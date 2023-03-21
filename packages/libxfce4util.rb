require 'package'

class Libxfce4util < Package
  description 'Utility library for the Xfce4 desktop environment'
  homepage 'https://xfce.org/'
  version '4.18.1'
  license 'LGPL-2+ and GPL-2+'
  compatibility 'all'
  source_url 'https://archive.xfce.org/src/xfce/libxfce4util/4.18/libxfce4util-4.18.1.tar.bz2'
  source_sha256 '8a52063a5adc66252238cad9ee6997909b59983ed21c77eb83c5e67829d1b01f'

  depends_on 'gobject_introspection'

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
