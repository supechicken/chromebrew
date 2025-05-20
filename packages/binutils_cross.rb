require 'package'

class Binutils_cross < Package
  description 'The GNU Binutils are a collection of binary tools.'
  homepage 'https://www.gnu.org/software/binutils/'
  version "2.44"
  license 'GPL-3+'
  compatibility 'all'
  source_url "https://sourceware.org/pub/binutils/releases/binutils-#{version.split('-').first}.tar.zst"
  source_sha256 '79cb120b39a195ad588cd354aed886249bfab36c808e746b30208d15271cc95c'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: 'e5c64aca4584a2c275d37e58a9afc6c6c5fdf32d6e2edcff0df2bf38fb7311d2',
     armv7l: 'e5c64aca4584a2c275d37e58a9afc6c6c5fdf32d6e2edcff0df2bf38fb7311d2',
       i686: '67ce1feb3920893481eca99b0cb2a26a5b3192abdcea8311d3515a8d435e0da9',
     x86_64: 'b7397812e623ee019376fe436d839c093ba59afab64d39555457536eeae8fe0e'
  })

  depends_on 'elfutils' # R
  depends_on 'flex' # R
  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'zlib' # R
  depends_on 'zstd' # R

  no_mold

  def self.prebuilt
    system 'aclocal && automake', chdir: 'ld'
  end

  def self.build
    target = 'aarch64-cros-linux-gnu'
    sysroot = File.join(CREW_PREFIX, "lib/#{target}")

    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system <<~CMD
        ../configure \
          --target=#{target} \
          --prefix=#{sysroot} \
          --bindir=#{CREW_PREFIX}/bin \
          --with-sysroot=#{sysroot} \
          --disable-gdb \
          --disable-gdbserver \
          --disable-maintainer-mode \
          --disable-nls \
          --enable-64-bit-bfd \
          --enable-colored-disassembly \
          --enable-install-libiberty \
          --enable-ld=default \
          --enable-lto \
          --enable-plugins \
          --enable-relro \
          --enable-shared \
          --enable-threads \
          --enable-vtable-verify \
          --with-bugurl=https://github.com/chromebrew/chromebrew/issues/new \
          --with-pic \
          --with-pkgversion=Chromebrew \
          --with-system-zlib
      CMD
      system 'make'
    end
  end

  def self.check
    system 'make -O check || true', chdir: 'build'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install', chdir: 'build'
  end
end
