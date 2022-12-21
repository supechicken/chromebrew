require 'package'

class Libreoffice < Package
  description ''
  homepage 'https://www.libreoffice.org/'
  license ''
  version '7.4.4.1'
  compatibility 'all'

  source_url 'https://gerrit.libreoffice.org/core.git'
  git_hashtag 'libreoffice-7.4.4.1'

  depends_on 'gtk3'
  depends_on 'hunspell'
  depends_on 'nspr'
  depends_on 'nss'
  depends_on 'qtbase'
  depends_on 'libjpeg'
  depends_on 'sommelier'

  def self.build
    system "./autogen.sh #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end