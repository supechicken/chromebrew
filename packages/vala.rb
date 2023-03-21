require 'package'

class Vala < Package
  description 'Vala is a programming language that aims to bring modern programming language features to GNOME developers.'
  homepage 'https://wiki.gnome.org/Projects/Vala'
  version '0.56.4'
  license 'LGPL-2.1+'
  compatibility 'all'
  source_url 'https://gitlab.gnome.org/GNOME/vala.git'
  git_hashtag version

  depends_on 'autoconf_archive' => :build
  depends_on 'autoconf213' => :build
  depends_on 'graphviz'
  depends_on 'libxslt'
  depends_on 'glib'
  depends_on 'dbus'
  depends_on 'glibc' # R
  git_fetchtags
  gnome

  def self.build
    # Bootstrap vala
    FileUtils.mkdir_p 'bootstrap_install'
    system 'git clone https://gitlab.gnome.org/Archive/vala-bootstrap.git'
    Dir.chdir('vala-bootstrap') do
      system 'git checkout b2beeaccdf2307ced172646c2ada9765e1747b28'
      FileUtils.touch Dir['*/*.stamp']

      system 'autoreconf -fi'
      system ({ 'VALAC' => '/no-valac' }), "./configure --prefix=#{Dir.pwd}/../bootstrap_install"
      system 'mold -run make'
      system 'make install'
    end

    system ({'VALAC' => "#{Dir.pwd}/bootstrap_install/bin/valac"}), <<~BUILD
      ./autogen.sh #{CREW_OPTIONS} \
        --disable-maintainer-mode \
        --disable-valadoc
    BUILD

    system 'mold -run make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
