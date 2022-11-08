require 'package'

class Crouton_xiwi < Package
  description 'X.org X11 backend running unaccelerated in a Chromium OS window.'
  homepage 'https://github.com/dnschneid/crouton'
  license 'BSD-3'
  compatibility 'all'
  version '1.0'

  source_url 'https://github.com/dnschneid/crouton.git'
  git_hashtag 'master'

  depends_on 'xorg_dummy_driver'

  def self.patch
    system 'sed', '-i', 's#/var/run/crouton-ext#/tmp/xiwi-ext#g', 'fbserver.c', 'findnacld.c', chdir: 'src'
  end

  def self.build
    Dir.chdir('src') do
      system 'cc', '-I', '.', '-lX11', '-lXfixes', '-lXdamage', '-lXext', '-lXtst', 'fbserver.c', '-o', 'xiwi_fbserver'
      system 'cc', '-I', '.', 'findnacld.c', '-o', 'xiwi_findnacld'
    end
  end

  def self.install
    FileUtils.mkdir_p [ File.join(CREW_DEST_PREFIX, 'bin'), File.join(CREW_DEST_PREFIX, 'etc') ]

    FileUtils.install 'src/xiwi_fbserver', File.join(CREW_DEST_PREFIX, 'bin/'), mode: 0o755
    FileUtils.install 'src/xiwi_findnacld', File.join(CREW_DEST_PREFIX, 'bin/'), mode: 0o755
    FileUtils.install 'chroot-bin/croutonfindnacl', File.join(CREW_DEST_PREFIX, 'bin/xiwi_findnacl'), mode: 0o755
    FileUtils.install 'chroot-etc/xorg-dummy.conf', File.join(CREW_DEST_PREFIX, 'etc/'), mode: 0o755

    Dir.chdir('')
  end
end