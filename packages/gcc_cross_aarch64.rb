require 'package'

class Gcc_cross_aarch64 < Package
  description 'The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go.'
  homepage 'https://www.gnu.org/software/gcc/'
  version "14.2.0"
  license 'GPL-3, LGPL-3, libgcc, FDL-1.2'
  compatibility 'all'
  source_url 'https://github.com/gcc-mirror/gcc.git'
  git_hashtag "releases/gcc-#{version.split('-').first}"
  binary_compression 'tar.zst'

  depends_on 'binutils_cross' => :build
  depends_on 'ccache' => :build
  depends_on 'dejagnu' => :build # for test
  depends_on 'glibc' # R
  depends_on 'gmp' # R
  depends_on 'isl' # R
  depends_on 'libssp' # L
  depends_on 'mpc' # R
  depends_on 'mpfr' # R
  depends_on 'zlib' # R
  depends_on 'zstd' # R

  no_mold
  no_shrink
  no_env_options

  def self.build
    target = 'aarch64-cros-linux-gnu'
    sysroot = File.join(CREW_PREFIX, "lib/#{target}")

    build_opts = %W[
      --prefix=#{CREW_PREFIX}
      --libdir=#{CREW_LIB_PREFIX}
      --program-prefix=#{target}-
      --with-local-prefix=#{sysroot}
      --with-sysroot=#{sysroot}
      --with-build-sysroot=#{sysroot}
      --with-native-system-header-dir=/include
      --build=#{CREW_TARGET}
      --host=#{CREW_TARGET}
      --target=#{target}
      --program-prefix=#{target}-
      --disable-bootstrap
      --disable-install-libiberty
      --disable-libmpx
      --disable-libssp
      --disable-multilib
      --disable-nls
      --disable-werror
      --enable-cet=auto
      --enable-checking=release
      --enable-clocale=gnu
      --enable-default-pie
      --enable-default-ssp
      --enable-gnu-indirect-function
      --enable-gnu-unique-object
      --enable-lto
      --enable-plugin
      --enable-shared
      --enable-symvers
      --enable-threads=posix
      --with-gcc-major-version-only
      --with-gmp
      --with-isl
      --with-mpc
      --with-mpfr
      --with-pic
      --with-system-libunwind
      --with-system-zlib
    ].join(' ')

    FileUtils.mkdir_p 'builddir'
    Dir.chdir('builddir') do
      configure_env =
        {
          LIBRARY_PATH: CREW_LIB_PREFIX,
                CFLAGS: '-fPIC -pipe',
              CXXFLAGS: '-fPIC -pipe'
        }.transform_keys(&:to_s)

      system configure_env, "../configure #{build_opts} --enable-languages=c,c++"

      # LIBRARY_PATH=#{CREW_LIB_PREFIX} needed for x86_64 to avoid:
      # /usr/local/bin/ld: cannot find crti.o: No such file or directory
      # /usr/local/bin/ld: cannot find /usr/lib64/libc_nonshared.a
      system({ LIBRARY_PATH: CREW_LIB_PREFIX }.transform_keys(&:to_s), "make -j #{CREW_NPROC} || make -j1")
    end
  end

  def self.install
    make_env =
      {
        LIBRARY_PATH: CREW_LIB_PREFIX,
             DESTDIR: CREW_DEST_DIR
      }.transform_keys(&:to_s)

    system make_env, 'make', 'install-gcc'

    %w[libgcc libstdc++-v3 libgomp libgfortran libquadmath libatomic].each do |t|
      system make_env, 'make', "install-target-#{t}"
    end
  end
end
