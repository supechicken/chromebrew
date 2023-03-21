require 'package'

class Xfce4_panel < Package
  description 'Next generation panel for the XFCE desktop environment'
  homepage 'https://xfce.org/'
  version '4.19.0'
  license 'GPL-2+ and LGPL-2.1+'
  compatibility 'all'
  source_url 'https://archive.xfce.org/src/xfce/xfce4-panel/4.19/xfce4-panel-4.19.0.tar.bz2'
  source_sha256 '92eaf45232294d8945709e444c6088973bc2b40d3b85f5269ff88a26ac76933f'

  depends_on 'libwnck'
  depends_on 'libxfce4ui'
  depends_on 'xfconf'
  depends_on 'garcon'
  depends_on 'exo'
  depends_on 'gtk3'

  def self.patch
    system 'filefix'
  end

  def self.build
    system "./configure #{CREW_OPTIONS} --disable-static --enable-gio-unix"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end

  def self.postinstall
    system 'gtk-update-icon-cache', '-f', '-t', "#{CREW_PREFIX}/share/icons/hicolor"
  end
end
