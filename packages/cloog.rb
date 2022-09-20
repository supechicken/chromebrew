require 'package'

class Cloog < Package
  description 'The CLooG Code Generator in the Polytope Model'
  homepage 'https://github.com/periscop/cloog'
  @_commit = 'c676b5b052a34ca58bb6be68047d4841c8354e19'
  version "0.20.0+#{@_commit[0, 7]}"
  license 'LGPL-2.1'
  compatibility 'all'

  source_url 'https://github.com/periscop/cloog.git'
  git_hashtag @_commit

  def self.build
    system 'autoreconf', '-i'
    system "./configure #{CREW_OPTIONS} --with-isl=system --with-osl=system"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end

  def self.check
    system 'make', 'check'
  end
end
