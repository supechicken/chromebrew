require 'package'

class Consolekit < Package
  description 'A framework for defining and tracking users, login sessions, and seats'
  homepage 'https://github.com/ConsoleKit2/ConsoleKit2'
  version '1.2.2'
  license 'GPL-2+'
  compatibility 'aarch64 armv7l x86_64'
  source_url "https://github.com/ConsoleKit2/ConsoleKit2/archive/#{version}.tar.gz"
  source_sha256 '104fd9f41c2d572ad62f4032de46c4c384c3522602b0ad953cf55759c6c64c1d'
  binary_compression 'tar.xz'

  binary_sha256({
    aarch64: '4b9173ec6798adc23824c4189a050744b888de6b58d60442d1ec89bf0df81443',
     armv7l: '4b9173ec6798adc23824c4189a050744b888de6b58d60442d1ec89bf0df81443',
     x86_64: '61b5b664b28cc6f5ce61d4065849ff8ebf1ac612140686c9178ef9b915fb3372'
  })

  depends_on 'dbus'
  depends_on 'libx11'
  depends_on 'polkit'
  depends_on 'linux_pam'
  depends_on 'eudev'
  depends_on 'xmlto' => :build

  def self.build
    system "env #{CREW_ENV_OPTIONS} \
      ./autogen.sh  \
      #{CREW_CONFIGURE_OPTIONS} \
      --sysconfdir=#{CREW_PREFIX}/etc  \
      --sbindir=#{CREW_PREFIX}/usr/bin  \
      --with-rundir=/run  \
      --libexecdir=#{CREW_LIB_PREFIX}/ConsoleKit  \
      --localstatedir=/var  \
      --enable-polkit  \
      --enable-pam-module  \
      --enable-udev-acl  \
      --enable-libevdev  \
      --with-dbus-services=#{CREW_PREFIX}/share/dbus-1/services  \
      --with-xinitrc-dir=#{CREW_PREFIX}/etc/X11/xinit/xinitrc.d  \
      --with-pam-module-dir=#{CREW_LIB_PREFIX}/security  \
      --without-systemdsystemunitdir  \
      --disable-cgroups"
    system 'make'
    # From Arch:
    system 'echo "d /run/ConsoleKit 0755 - - -" > consolekit.tmpfiles.conf'
  end

  def self.install
    system "make DESTDIR=#{CREW_DEST_DIR} install"
    FileUtils.mkdir_p "#{CREW_DEST_LIB_PREFIX}/tmpfiles.d"
    FileUtils.install 'consolekit.tmpfiles.conf', "#{CREW_DEST_LIB_PREFIX}/tmpfiles.d/consolekit.conf", mode: 0o644
  end
end
