require 'package'
require 'convenience_functions'

class Google_chrome_unstable < Package
  description 'Google Chrome is a fast, easy to use, and secure web browser. (Dev Channel)'
  homepage 'https://www.google.com/chrome/'
  @update_channel = 'unstable'
  version '137.0.7127.2-1'
  license 'google-chrome'
  compatibility 'x86_64'
  min_glibc '2.28'
  source_url "https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-#{@update_channel}/google-chrome-#{@update_channel}_#{@version}_amd64.deb"
  source_sha256 '6e30e4a33e8a5b4991d9594f008dc43165d4c72ac4b1612f2541d3c5a40b7812'

  depends_on 'nss'
  depends_on 'cairo'
  depends_on 'gtk3'
  depends_on 'expat'
  depends_on 'cras'

  no_compile_needed
  no_shrink

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"

    FileUtils.mv 'usr/share', CREW_DEST_PREFIX
    FileUtils.mv "opt/google/chrome-#{@update_channel}", "#{CREW_DEST_PREFIX}/share"

    FileUtils.ln_s "../share/chrome/google-chrome-#{@update_channel}", "#{CREW_DEST_PREFIX}/bin/google-chrome-#{@update_channel}"
  end

  def self.postinstall
    ConvenienceFunctions.set_default_browser("Chrome (#{@update_channel.capitialize})", "google-chrome-#{@update_channel}")
  end

  def self.preremove
    ConvenienceFunctions.unset_default_browser("Chrome (#{@update_channel.capitialize})", "google-chrome-#{@update_channel}")
  end
end
