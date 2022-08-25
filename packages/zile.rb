require 'package'

class Zile < Package
  description 'A small, fast, and powerful Emacs clone'
  homepage 'http://www.gnu.org/software/zile/'
  version '2.6.2'
  license 'GPL-3+'
  compatibility 'all'
  source_url 'https://ftpmirror.gnu.org/zile/zile-2.6.2.tar.gz'
  source_sha256 '77eb7daff3c98bdc88daa1ac040dccca72b81dc32fc3166e079dd7a63e42c741'

  depends_on 'bdwgc'
  depends_on 'help2man' => :build

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
