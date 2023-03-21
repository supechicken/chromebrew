require 'package'

class Libxfce4ui < Package
  description 'Replacement of the old libxfcegui4 library'
  homepage 'https://xfce.org/'
  version '4.18.2'
  license 'LGPL-2+ and GPL-2+'
  compatibility 'all'
  source_url 'https://archive.xfce.org/src/xfce/libxfce4ui/4.18/libxfce4ui-4.18.2.tar.bz2'
  source_sha256 'ad602d0427e6c40c3eb53db393c607151a039aec58f1f197712c169c5fe49407'

  depends_on 'gtk3'
  depends_on 'gtk2'
  depends_on 'pygtk' # For gtk+
  depends_on 'xfconf'

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
