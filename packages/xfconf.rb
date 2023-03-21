require 'package'

class Xfconf < Package
  description 'Xfce hierarchical (tree-like) configuration system'
  homepage 'https://xfce.org/'
  version '4.18.0'
  license 'GPL-2+'
  compatibility 'all'
  source_url 'https://archive.xfce.org/src/xfce/xfconf/4.18/xfconf-4.18.0.tar.bz2'
  source_sha256 '2e8c50160bf800a807aea094fc9dad81f9f361f42db56607508ed5b4855d2906'

  depends_on 'gobject_introspection' # For --enable-gsettings-backend
  depends_on 'libxfce4util'
  depends_on 'vala' => :build

  def self.build
    system "./configure #{CREW_OPTIONS} --enable-gsettings-backend"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
