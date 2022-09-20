require 'package'

class Asciidoc < Package
  description 'AsciiDoc is a presentable text document format for writing articles, UNIX man pages and other small to medium sized documents.'
  homepage 'http://asciidoc.org/'
  @_ver = '10.2.0'
  version @_ver
  license 'GPL-2'
  compatibility 'all'
  source_url "https://github.com/asciidoc/asciidoc-py3.git"
  git_hashtag @_ver

  def self.prebuild
    system 'autoconf'
    system "sed -i 's,/etc/vim,#{CREW_PREFIX}/etc/vim,g' Makefile.in"
  end

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/vim"
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
