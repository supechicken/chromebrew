require 'package'

class Xfce4_dev_tools < Package
  description 'Xfce4 development tools'
  homepage 'https://xfce.org/'
  version '4.19.0'
  license 'GPL-2+'
  compatibility 'all'
  source_url 'https://archive.xfce.org/src/xfce/xfce4-dev-tools/4.19/xfce4-dev-tools-4.19.0.tar.bz2'
  source_sha256 'ac9fd11f9749303683d80480dac6bbb91c8bf160d8ea5a794bb4f2041eb61d1d'

  depends_on 'gtk_doc'

  def self.patch
    system 'filefix'
  end

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
