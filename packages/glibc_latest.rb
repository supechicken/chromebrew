# Adapted from Arch Linux glibc PKGBUILD at:
# https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/blob/main/PKGBUILD

class Glibc_latest < Package
  version '2.39'
  homepage 'https://www.gnu.org/software/libc'
  compatibility 'all'
  license 'GPL-2.0+ LGPL-2.1+'
  source_url 'https://github.com/bminor/glibc.git'
  git_hashtag 'glibc-2.39'

  def self.build
    ENV['CC'] = 'clang'
    ENV['CXX'] = 'clang++'

    FileUtils.mkdir_p %w[glibc-build lib32-glibc-build]

    Dir.chdir('glibc-build') do
      File.open('configparms', 'a') do |io|
        io.write <<~EOT
          slibdir=/usr/local/lib
          rtlddir=/usr/local/lib
          sbindir=/usr/lcoal/bin
          rootsbindir=/usr/local/bin
        EOT
      end

      puts '????'

      system %W[
        mold -run ../configure
          --build=x86_64-cros-linux-gnu --host=x86_64-cros-linux-gnu --target=x86_64-cros-linux-gnu
          --prefix=/usr/local
          --libdir=/usr/local/lib
          --libexecdir=/usr/local/lib
          --with-headers=/usr/local/include
          --with-bugurl=https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/issues
          --enable-bind-now
          --enable-fortify-source
          --enable-kernel=4.4
          --enable-multi-arch
          --enable-stack-protector=strong
          --enable-systemtap
          --enable-cet
          --disable-nscd
          --disable-profile
          --disable-werror
      ]

      puts '????'

      system 'make'
    end

=begin
    Dir.chdir('lib32-glibc-build') do
      ENV['CC'] = "gcc -m32 -mstackrealign"
      export CXX = "g++ -m32 -mstackrealign"

      File.open('configparms', 'a') do |io|
        io.write <<~EOT
          slibdir=/usr/local/lib32
          rtlddir=/usr/local/lib32
          sbindir=/usr/lcoal/bin
          rootsbindir=/usr/local/bin
        EOT
      end


      system %W[
        mold -run ../configure
          --host=i686-cros-linux-gnu
          --prefix=/usr/local
          --libdir=/usr/local/lib32
          --libexecdir=/usr/local/lib32
          --with-headers=/usr/local/include
          --with-bugurl=https://gitlab.archlinux.org/archlinux/packaging/packages/glibc/-/issues
          --enable-bind-now
          --enable-fortify-source
          --enable-kernel=4.4
          --enable-multi-arch
          --enable-stack-protector=strong
          --enable-systemtap
          --disable-nscd
          --disable-profile
          --disable-werror
      ]

      system 'make'
    end
=end
  end

  def self.install
    %w[glibc-build lib32-glibc-build].each do |build|
      system %W[mold -run make DESTDIR=#{CREW_DEST_DIR} install], chdir: build
    end
  end
end
