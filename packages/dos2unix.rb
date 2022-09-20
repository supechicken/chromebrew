require 'package'

class Dos2unix < Package
  description 'dos2unix includes utilities to convert text files with DOS or Mac line endings to Unix line endings and vice versa.'
  homepage 'http://freecode.com/projects/dos2unix'
  version '7.4.3'
  license 'BSD-2'
  compatibility 'all'
  source_url 'https://downloads.sourceforge.net/project/dos2unix/dos2unix/7.4.3/dos2unix-7.4.3.tar.gz'
  source_sha256 'b68db41956daf933828423aa30510e00c12d29ef5916e715e8d4e694fe66ca72'

  depends_on 'gettext' => :build

  def self.build
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    FileUtils.install %w[dos2unix mac2unix unix2dos unix2mac], "#{CREW_DEST_PREFIX}/bin", mode: 0o755
  end
end
