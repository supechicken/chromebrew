require 'package'

class Dropbox_uploader < Package
  description 'Dropbox Uploader is a BASH script which can be used to upload, download, list or delete files from Dropbox, an online file sharing, synchronization and backup service.'
  homepage 'https://github.com/andreafabrizi/Dropbox-Uploader'
  @_commit = '11fb8f736064730dd21ff85d68dfcc8aacfdf559'
  version "1.0+#{commit[0, 7]}"
  compatibility 'all'
  license 'GPL-3'

  source_url 'https://github.com/andreafabrizi/Dropbox-Uploader.git'
  git_hashtag @_commit

  no_compile_needed

  depends_on 'libcurl'

  def self.patch
    system "sed -i 's,dropbox_uploader.sh,dropbox_uploader,g' dropShell.sh"
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"

    FileUtils.install 'dropShell.sh', "#{CREW_DEST_PREFIX}/bin/dropshell", mode: 0o755
    FileUtils.install 'dropbox_uploader.sh', "#{CREW_DEST_PREFIX}/bin/dropbox_uploader", mode: 0o755

    puts <<~EOT.lightblue
      Type 'dropbox_uploader' and follow the instructions to finish the installation.
      To execute The Interactive Dropbox SHELL, type 'dropshell'.
    EOT
  end
end
