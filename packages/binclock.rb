require 'package'

class Binclock < Package
  description 'Ncurses clock, with time displayed in colourful binary'
  homepage 'https://github.com/JohnAnthony/Binary-Clock'
  @_commit = '3883e8876576a45162b9a128d8317b20f98c5140'
  version @_commit[0, 7]
  license 'GPL-2'
  compatibility 'all'

  source_url 'https://github.com/JohnAnthony/Binary-Clock.git'
  git_hashtag @_commit

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/binclock/3883e8_armv7l/binclock-3883e8-chromeos-armv7l.tar.xz',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/binclock/3883e8_armv7l/binclock-3883e8-chromeos-armv7l.tar.xz',
       i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/binclock/3883e8_i686/binclock-3883e8-chromeos-i686.tar.xz',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/binclock/3883e8_x86_64/binclock-3883e8-chromeos-x86_64.tar.xz'
  })
  binary_sha256({
    aarch64: '265d4488274d213d0663f7aebb3da8c81b046edd8c6cef4101a70dcce6a39b18',
     armv7l: '265d4488274d213d0663f7aebb3da8c81b046edd8c6cef4101a70dcce6a39b18',
       i686: 'bb32dd6577ab50e82170e6b63843ef0c46290d6fd04b67482f3f604cff59ae02',
     x86_64: 'aae91be20e29e463d85d419c19ba534a0533f3b5b035a93a3060c18bf22f7c3f'
  })

  depends_on 'ncurses'

  def self.build
    system "sed -i 's,#include <ncurses.h>,#include <#{CREW_PREFIX}/include/ncurses/ncurses.h>,' binclock.c"
    system "sed -i 's,/usr/bin,#{CREW_PREFIX}/bin,g' Makefile"
    system "sed -i 's,/usr/share,#{CREW_PREFIX}/share,g' Makefile"
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p %W[#{CREW_DEST_PREFIX}/bin #{CREW_DEST_MAN_PREFIX}/man1]
    FileUtils.install 'binclock', "#{CREW_DEST_PREFIX}/bin", mode: 0o755
    FileUtils.install 'binclock.1', "#{CREW_DEST_MAN_PREFIX}/man1"
  end
end
