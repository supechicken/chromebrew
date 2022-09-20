require 'package'

class Clmystery < Package
  description 'A command-line murder mystery'
  homepage 'https://github.com/veltman/clmystery'
  @_commit = 'a159819c33fd37b4b0b079dc265c8b137ca71be6'
  version @_commit[0, 7]
  license 'MIT'
  compatibility 'all'

  source_url 'https://github.com/veltman/clmystery.git'
  git_hashtag @_commit

  no_compile_needed

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_HOME}/clmystery"
    FileUtils.cp_r Dir['*'], "#{CREW_DEST_HOME}/clmystery"
  end

  def self.postinstall
    puts
    puts 'Learn command line basics by solving a murder mystery.'.lightblue
    puts
    puts 'To start, execute the following:'.lightblue
    puts 'cd ~/clmystery'.lightblue
    puts 'cat instructions'.lightblue
    puts
  end
end
