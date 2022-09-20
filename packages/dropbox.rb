require 'package'

class Dropbox < Package
  description 'Dropbox simplifies the way you create, share and collaborate.  Bring your photos, docs, and videos anywhere and keep your files safe.'
  homepage 'https://www.dropbox.com/'
  version '48.4.58-1'
  license 'Dropbox-TOS'
  compatibility 'i686,x86_64'

  case ARCH
  when 'i686'
    source_url 'https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86-48.4.58.tar.gz'
    source_sha256 '3affb0ade20e26adf337489c6b780a94ddd8d51712a3bd88be2def38b5689570'
  when 'x86_64'
    source_url 'https://clientupdates.dropboxstatic.com/dbx-releng/client/dropbox-lnx.x86_64-48.4.58.tar.gz'
    source_sha256 'bd948a712e21c36d01ad17e72a5893972dd9411408561c3b806dbca2c32ae9a4'
  end

  binary_url({
    i686: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/dropbox/48.4.58_i686/dropbox-48.4.58-chromeos-i686.tar.xz',
    x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/dropbox/48.4.58_x86_64/dropbox-48.4.58-chromeos-x86_64.tar.xz'
  })
  binary_sha256({
    i686: '1d272702286bd31f3235ba0eb8369946f45fb4ea919b35d1ec4ed060a1578b69',
    x86_64: 'c2c699372e4646ce5ed542fa189c08dc44dea1ae312f7401f1f385279e1b2ded'
  })

  no_compile_needed

  depends_on 'python3'
  depends_on 'libxslt'

  def self.build
    downloader 'https://linux.dropbox.com/packages/dropbox.py', 'SKIP'
    system 'sed', '-i', "s,~/.dropbox-dist,#{CREW_LIB_PREFIX}/dropbox,g", 'dropbox.py'

    @dropboxd_wrapper = <<~EOF
      #!/bin/bash -e

      cd #{CREW_LIB_PREFIX}/dropbox
      exec ./dropboxd "${@}"
    EOF
  end

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"

    File.write "#{CREW_DEST_PREFIX}/bin/dropboxd", @dropboxd_wrapper, perm: 0o755

    FileUtils.mv '.dropbox-dist', "#{CREW_DEST_LIB_PREFIX}/dropbox"
    FileUtils.install 'dropbox.py', "#{CREW_DEST_PREFIX}/bin/dropbox", mode: 0o755
  end

  def self.postinstall
    puts
    puts "To finish the installation, execute 'dropboxd'.".lightblue
    puts 'Login to dropbox.com, highlight the url and paste into Chrome.'.lightblue
    puts 'Type Ctrl+C to exit dropboxd after linking your system.'.lightblue
    puts "Execute 'dropbox start' and after syncing is complete, files will be available in ~/Dropbox.".lightblue
    puts "Execute 'dropbox' to see the full list of available options.".lightblue
    puts
  end
end
