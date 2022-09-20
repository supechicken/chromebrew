require 'package'

class Fslint < Package
  description 'FSlint is a utility to find and clean various forms of lint on a filesystem.'
  homepage 'https://www.pixelbeat.org/fslint/'
  @_commit = '10027536342c0bf5a3458e046674d96b2b83aa88'
  version "2.46+#{@_commit[0, 7]}"
  license 'GPL-2'
  compatibility 'all'

  source_url 'https://github.com/pixelb/fslint.git'
  git_hashtag @_commit

  no_compile_needed

  depends_on 'help2man'

  def self.build
    system 'find fslint/ -type f -exec chmod +x {} \+'

    Dir['fslint/*'].select {|e| File.file?(e) } .each do |f|
      system "help2man -N #{f} > man/#{File.basename(f)}.1"
    end
  end

  def self.install
    FileUtils.mkdir_p %W[
      #{CREW_DEST_PREFIX}/bin
      #{CREW_DEST_PREFIX}/share/applications
      #{CREW_DEST_PREFIX}/share/icons/hicolor/256x256/apps
      #{CREW_DEST_PREFIX}/lib/fslint
      #{CREW_DEST_MAN_PREFIX}/man1
    ]

    FileUtils.cp_r Dir['*'], "#{CREW_DEST_PREFIX}/lib/fslint/"

    Dir['fslint/*'].select {|e| File.file?(e) } .each do |f|
      FileUtils.ln_s "#{CREW_PREFIX}/lib/fslint/#{f}", "#{CREW_DEST_PREFIX}/bin/#{File.basename(f)}"
    end

    FileUtils.ln_s "#{CREW_PREFIX}/lib/fslint/fslint-gui", "#{CREW_DEST_PREFIX}/bin/fslint-gui"
    FileUtils.ln_s "#{CREW_PREFIX}/lib/fslint/fslint.desktop", "#{CREW_DEST_PREFIX}/share/applications/fslint.desktop"
    FileUtils.ln_s "#{CREW_PREFIX}/lib/fslint/fslint_icon.png", "#{CREW_DEST_PREFIX}/share/icons/hicolor/256x256/apps/fslint_icon.png"

    FileUtils.cp_r Dir['man/*'], "#{CREW_DEST_MAN_PREFIX}/man1"
  end
end
