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
      system 'cc', '-lX11', '-lXfixes', '-lXdamage', '-lXext', '-lXtst', 'fbserver.c', '-o', 'xiwi_fbserver'
      system 'cc', 'findnacld.c', 'xiwi_findnacld'
    end
  end

  def self.install
    FileUtils.mkdir_p File.join(CREW_DEST_PREFIX, 'bin')

    Dir.chdir('src') do
      FileUtils.install 'xiwi_fbserver', File.join(CREW_DEST_PREFIX, 'bin'), mode: 0o755
      FileUtils.install 'xiwi_findnacld', File.join(CREW_DEST_PREFIX, 'bin'), mode: 0o755
    end
  end
end