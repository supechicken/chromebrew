require 'package'

class Fortunes < Package
  description 'Over 15000 cookies for the fortune program.'
  homepage 'https://packages.debian.org/sid/fortunes'
  version '1.99.1'
  license 'BSD'
  compatibility 'all'
  source_url 'https://httpredir.debian.org/debian/pool/main/f/fortune-mod/fortune-mod_1.99.1.orig.tar.gz'
  source_sha256 'fc51aee1f73c936c885f4e0f8b6b48f4f68103e3896eaddc6a45d2b71e14eace'

  no_compile_needed

  depends_on 'fortune'

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/share/games/fortunes"
    FileUtils.cp_r Dir['datfiles/*'], "#{CREW_DEST_PREFIX}/share/games/fortunes/"
  end
end
