require 'package'

class Fzf < Package
  description 'A command-line fuzzy finder'
  homepage 'https://github.com/junegunn/fzf'
  version '0.33.0'
  license 'MIT and BSD-with-disclosure'
  compatibility 'aarch64,armv7l,x86_64'

  source_url 'https://github.com/junegunn/fzf.git'
  git_hashtag version

  depends_on 'go' => :build

  def self.patch
    system "sed -i 's,bin/fzf,#{CREW_PREFIX}/bin/fzf,' Makefile"
  end

  def self.build
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    system 'make', "DESTDIR=#{DESTDIR}", 'install'
  end
end
