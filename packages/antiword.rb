require 'package'

class Antiword < Package
  description 'Antiword is a free MS Word reader for Linux and RISC OS.'
  homepage 'http://www.winfield.demon.nl/'
  version '0.37-3'
  license 'GPL-2'
  compatibility 'all'
  source_url 'http://www.winfield.demon.nl/linux/antiword-0.37.tar.gz'
  source_sha256 '8e2c000fcbc6d641b0e6ff95e13c846da3ff31097801e86702124a206888f5ac'

  def self.patch
    system "find . -type f -exec sed -i 's,/usr/share,#{CREW_PREFIX}/share,g' {} \\;"
  end

  def self.build
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p %W[
      #{CREW_DEST_HOME}/.antiword
      #{CREW_DEST_PREFIX}/bin
      #{CREW_DEST_MAN_PREFIX}/man1
    ]

    FileUtils.install 'antiword', "#{CREW_DEST_PREFIX}/bin", mode: 0o755
    FileUtils.install 'Docs/antiword.1', "#{CREW_DEST_MAN_PREFIX}/man1", mode: 0o644

    FileUtils.mv 'Resources/', "#{CREW_DEST_PREFIX}/share/antiword"
    FileUtils.install 'Resources/UTF-8.txt', "#{CREW_DEST_HOME}/.antiword", mode: 0o644
  end
end
