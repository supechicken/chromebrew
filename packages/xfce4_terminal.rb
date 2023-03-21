require 'package'

class Xfce4_terminal < Package
  description 'Modern terminal emulator primarily for the Xfce desktop environment'
  homepage 'https://xfce.org/'
  version '1.0.4'
  license 'GPL-2+'
  compatibility 'all'
  source_url "https://archive.xfce.org/src/apps/xfce4-terminal/1.0/xfce4-terminal-#{version}.tar.bz2"
  source_sha256 '78e55957af7c6fc1f283e90be33988661593a4da98383da1b0b54fdf6554baf4'

  depends_on 'desktop_file_utilities'
  depends_on 'vte'
  depends_on 'exo' => :build
  depends_on 'hicolor_icon_theme'
  depends_on 'libxfce4ui'
  depends_on 'startup_notification'
  depends_on 'wayland'

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
