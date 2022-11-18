require 'package'

class Sommelier < Package
  description 'Sommelier works by redirecting X11 programs to the built-in ChromeOS Exo Wayland server.'
  homepage 'https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/sommelier/'
  version 'sommelier_update_20221025'
  license 'BSD-Google'
  compatibility 'aarch64,armv7l,x86_64'
  source_url 'https://github.com/supechicken/crew-package-sommelier.git'
  git_branch version

  depends_on 'libdrm'
  depends_on 'libevdev'
  depends_on 'libxcb'
  depends_on 'libxcomposite' => :build
  depends_on 'libxfixes' => :build
  depends_on 'libxkbcommon'
  depends_on 'llvm'
  depends_on 'mesa'
  depends_on 'pixman'
  depends_on 'psmisc'
  depends_on 'wayland'
  depends_on 'xauth'
  depends_on 'xdpyinfo' # for xdpyinfo in sommelierrc script
  depends_on 'xsetroot' # for xsetroot in sommelierrc script
  depends_on 'xhost' # for xhost in sommelierrc script
  depends_on 'xrdb' # for xrdb in sommelierrc script
  depends_on 'xwayland'


  def self.preflight
    return if File.socket?('/var/run/chrome/wayland-0') || CREW_IN_CONTAINER

    abort 'This package is not compatible with your device :/'.lightred
  end

  def self.patch
    system 'cat patches/*.patch | (cd sommelier_src/; patch -p1)'
  end

  def self.build
    # gamepad functionality might not work on older exo wayland servers
    # disable gamepad support by default unless CREW_SOMMELIER_BUILD_WITH_GAMEPAD_SUPPORT is set to '1'
    gamepad = ENV.fetch('CREW_SOMMELIER_BUILD_WITH_GAMEPAD_SUPPORT', '0')

    Dir.chdir('sommelier_src') do
      system <<~BUILD
        meson #{CREW_MESON_OPTIONS} \
          -Dxwayland_path=#{CREW_PREFIX}/bin/Xwayland \
          -Dxwayland_gl_driver_path=#{CREW_LIB_PREFIX}/dri \
          -Dwith_tests=false \
          -Dgamepad=#{gamepad.eql?('1') ? 'true' : 'false'} \
          builddir
      BUILD

      system 'meson configure builddir'
      system 'samu -C builddir'
    end
  end

  def self.install
    FileUtils.mkdir_p %W[
      #{CREW_DEST_PREFIX}/bin
      #{CREW_DEST_PREFIX}/sbin
      #{CREW_DEST_PREFIX}/etc/env.d
      #{CREW_DEST_PREFIX}/etc/bash.d
    ]

    system "DESTDIR=#{CREW_DEST_DIR} samu -C sommelier_src/builddir install"

    FileUtils.mv "#{CREW_DEST_PREFIX}/bin/sommelier", "#{CREW_DEST_PREFIX}/bin/sommelier.elf"

    FileUtils.install 'sommelier-wrapper', "#{CREW_DEST_PREFIX}/bin/sommelier", mode: 0o755
    FileUtils.install 'sommelierd', "#{CREW_DEST_PREFIX}/bin/sommelierd", mode: 0o755
    FileUtils.install 'sommelierrc', "#{CREW_DEST_PREFIX}/etc/sommelierrc", mode: 0o644
    FileUtils.install 'sommelier.env', "#{CREW_DEST_PREFIX}/etc/env.d/sommelier", mode: 0o644

    #FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/lib/sommelier/"
    #FileUtils.mv 'dpi_checker/', "#{CREW_DEST_PREFIX}/lib/sommelier/dpi_checker"

    FileUtils.ln_s 'sommelierd', "#{CREW_DEST_PREFIX}/bin/startsommelier"
    FileUtils.ln_s 'sommelierd', "#{CREW_DEST_PREFIX}/bin/restartsommelier"
    FileUtils.ln_s 'sommelierd', "#{CREW_DEST_PREFIX}/bin/stopsommelier"

    File.write "#{CREW_DEST_PREFIX}/etc/bash.d/sommelier", 'startsommelier', perm: 0o644
  end

  def self.postinstall
=begin
    system 'ruby', "#{CREW_PREFIX}/lib/sommelier/dpi_checker/dpi_checker.rb"

    puts '', <<~RESTARTSOMMELIER_EOT.yellow
      To complete the installation, execute the following:

        source #{CREW_PREFIX}/etc/profile
        restartsommelier
    RESTARTSOMMELIER_EOT
=end

    puts <<~ENV_ADJUSTMENT_EOT.lightblue
      To adjust sommelier environment variables, edit #{CREW_PREFIX}/etc/env.d/sommelier
      Default values are in #{CREW_PREFIX}/etc/env.d/sommelier

      Run 'startsommelier' to start sommelier daemon.
      Run 'stopsommelier' to stop all sommelier daemon.
      Run 'restartsommelier' to restart sommelier daemon
    ENV_ADJUSTMENT_EOT

    puts <<~OTHER_INFO_EOT.orange
      After adjusting the screen scale in system settings, the DPI value in sommelier.dpi might become incorrect
      (this will lead to incorrect display scale in X11 applications)

      Run "ruby #{CREW_PREFIX}/lib/sommelier/dpi_checker/dpi_checker.rb" to regenerate the DPI file

      Please be aware that GUI applications may not work without the sommelier daemon running.
    OTHER_INFO_EOT
  end
end
