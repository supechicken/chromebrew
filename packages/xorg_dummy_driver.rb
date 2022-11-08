require 'package'

class Xorg_dummy_driver < Package
  description 'Virtual/offscreen frame buffer driver for the Xorg X server'
  homepage 'https://x.org'
  license 'MIT-with-advertising, ISC, BSD-3, BSD and custom'
  compatibility 'all'
  version '0.4.0'

  source_url 'https://gitlab.freedesktop.org/xorg/driver/xf86-video-dummy.git'
  git_hashtag "xf86-video-dummy-#{version}"

  def self.build
    system ({ 'NOCONFIGURE' => '1' }), './autogen.sh'
    system "mold -run ./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{DESTDIR}", 'install'
  end
end
