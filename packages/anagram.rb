require 'package'

class Anagram < Package
  description 'finds anagrams or permutations of words in the target phrase'
  homepage 'https://www.fourmilab.ch/anagram/'
  version '1.5'
  license 'public-domain'
  compatibility 'all'
  source_url 'https://www.fourmilab.ch/anagram/anagram-1.5.tar.gz'
  source_sha256 '62eca59318782e889118a0e130d454e1c397aedd99fc59b2194393bf0eff5348'

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'

    File.write 'anagram-wrapper', <<~EOF
      #!/bin/bash -e

      exec #{CREW_PREFIX}/share/anagram/bin/anagram \
        --dictionary #{CREW_PREFIX}/share/anagram/crossword.txt \
        --bindict #{CREW_PREFIX}/share/anagram/wordlist.bin "${@}"
    EOF
  end

  def self.install
    FileUtils.mkdir_p %W[
      #{CREW_DEST_PREFIX}/bin
      #{CREW_DEST_PREFIX}/share/anagram/bin
      #{CREW_DEST_MAN_PREFIX}/man1
    ]

    system "gzip -c -9 anagram.1 > #{CREW_DEST_MAN_PREFIX}/man1/anagram.1.gz"

    FileUtils.install 'anagram-wrapper', "#{CREW_DEST_PREFIX}/bin/anagram", mode: 0o755
    FileUtils.install 'anagram', "#{CREW_DEST_PREFIX}/share/anagram/bin", mode: 0o755
    FileUtils.install 'crossword.txt', "#{CREW_DEST_PREFIX}/share/anagram", mode: 0o644
    FileUtils.install 'wordlist.bin', "#{CREW_DEST_PREFIX}/share/anagram", mode: 0o644
  end
end
