require 'package'

class Colordiff < Package
  description "The Perl script colordiff is a wrapper for 'diff' and produces the same output but with pretty 'syntax' highlighting."
  homepage 'https://www.colordiff.org/'
  version '1.0.20'
  license 'GPL-2'
  compatibility 'all'

  source_url 'https://www.colordiff.org/colordiff-1.0.20.tar.gz'
  source_sha256 'e3b2017beeb9f619ebc3b15392f22810c882d1b657aab189623cffef351d7bcd'

  no_compile_needed

  depends_on 'perl'

  def self.patch
    system "sed -i 's,/etc,#{CREW_PREFIX}/etc,g' colordiff.pl"
    system "sed -i 's,/usr/bin/perl,#{CREW_PREFIX}/bin/perl,' colordiff.pl"
  end

  def self.install
    FileUtils.install 'colordiff.pl', "#{CREW_DEST_PREFIX}/bin/colordiff", mode: 0o755
    FileUtils.install 'cdiff.sh', "#{CREW_DEST_PREFIX}/bin/cdiff", mode: 0o755
    FileUtils.install 'colordiffrc', "#{CREW_DEST_PREFIX}/etc/colordiffrc", mode: 0o644

    system "gzip -c -9 cdiff.1 > #{CREW_DEST_MAN_PREFIX}/man1/cdiff.1.gz"
    system "gzip -c -9 colordiff.1 > #{CREW_DEST_MAN_PREFIX}/man1/colordiff.1.gz"
  
    FileUtils.mkdir_p CREW_DEST_HOME
    FileUtils.ln_s "#{CREW_PREFIX}/etc/colordiffrc", "#{CREW_DEST_HOME}/.colordiffrc"
  end
end
