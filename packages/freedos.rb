require 'package'

class Freedos < Package
  description 'FreeDOS is a free DOS-compatible operating system.'
  homepage 'https://www.freedos.org/'
  version '1.3'
  license 'GPL-2'
  compatibility 'all'
  source_url 'https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/official/FD13-LiveCD.zip'
  source_sha256 '250d3980b38d988ddfe100df1a5d09009c6fee17cbabd17274d5284e02a491c4'

  no_compile_needed

  depends_on 'libjpeg'
  depends_on 'wayland_protocols'
  depends_on 'hicolor_icon_theme'
  depends_on 'gtk3'
  depends_on 'qemu'

  def self.build
    loop do
      warn 'Enter the drive C: partition size (in MB) (must be >= 100 MB):'
      size = STDIN.gets.to_i

      if size > 100
        break
      else
        warn 'Enter a number greater than or equal to 100.'
      end
    end

    # See https://opensource.com/article/17/10/run-dos-applications-linux.
    FileUtils.mkdir_p "#{CREW_DEST_HOME}/dosfiles"

    system "qemu-img create freedos.img #{size}M"
    system 'qemu-system-i386 -m 16 -k en-us -rtc base=localtime -soundhw all -device cirrus-vga -display gtk -hda freedos.img -cdrom ./FD13LIVE.ISO -boot order=d'

    @freedos = <<~EOF
      #!/bin/bash -e

      exec qemu-system-i386 -m 16 -k en-us -rtc base=localtime \
        -soundhw all -device cirrus-vga -display gtk -hda #{HOME}/freedos.img \
        -drive file=fat:rw:$HOME/dosfiles/ -boot order=c
    EOF
  end

  def self.install
    FileUtils.mkdir_p CREW_DEST_HOME

    File.write "#{CREW_DEST_PREFIX}/bin/freedos", @freedos, perm: 0o755
    FileUtils.install 'freedos.img', CREW_DEST_HOME, mode: 0o644
  end

  def self.postinstall
    puts <<~EOT.lightblue

      Type 'freedos' to start.

      Add files to #{HOME}/dosfiles.

    EOT
  end
end
