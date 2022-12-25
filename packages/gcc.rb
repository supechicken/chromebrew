require 'package'

class Gcc < Package
  description 'The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go.'
  homepage 'https://www.gnu.org/software/gcc/'
  version '12.2.1-b80a690'
  license 'GPL-3, LGPL-3, libgcc, FDL-1.2'
  compatibility 'all'
  source_url 'https://github.com/gcc-mirror/gcc.git'
  git_hashtag 'b80a690673272919896ee5939250e50d882f2418'

  depends_on 'binutils' => :build
  depends_on 'ccache' => :build
  depends_on 'dejagnu' => :build # for test
  depends_on 'glibc' # R
  depends_on 'gmp' # R
  depends_on 'isl' # R
  depends_on 'libssp' # L
  depends_on 'mpc' # R
  depends_on 'mpfr' # R
  depends_on 'zlibpkg' # R
  depends_on 'zstd' # R

  no_env_options
  no_patchelf
  no_shrink

  no_zstd if ARCH == 'i686'

  @gcc_version = version.partition('.')[0]

  def self.prebuild
    @C99 = <<~EOF
      #!/usr/bin/env sh
      fl="-std=c99"
      for opt; do
        case "$opt" in
          -std=c99|-std=iso9899:1999) fl="";;
          -std=*) echo "`basename $0` called with non ISO C99 option $opt" >&2
              exit 1;;
        esac
      done
      exec gcc $fl ${1+"$@"}
    EOF

    @C89 = <<~EOF
      #!/usr/bin/env sh
      fl="-std=c89"
      for opt; do
        case "$opt" in
          -ansi|-std=c89|-std=iso9899:1990) fl="";;
          -std=*) echo "`basename $0` called with non ANSI/ISO C option $opt" >&2
                exit 1;;
        esac
      done
      exec gcc $fl ${1+"$@"}
    EOF
  end

  def self.build
    @gcc_global_opts = <<~BUILD.tr("\n", ' ')
      #{CREW_OPTIONS}

      --with-bugurl="https://github.com/chromebrew/chromebrew/issues/new"
      --with-native-system-header-dir=#{CREW_PREFIX}/include
      --with-gnu-ld=#{CREW_PREFIX}/bin/ld.mold
      --with-gcc-major-version-only
      --with-system-zlib

      --enable-__cxa_atexit
      --enable-gnu-indirect-function

      --disable-libssp
      --disable-werror

      --enable-bootstrap
      --enable-shared
      --enable-threads=posix
      --enable-default-pie
      --enable-default-ssp
      --enable-checking=release
      --enable-linker-build-id
      --enable-gnu-unique-object
    BUILD

    case ARCH
    when 'aarch64', 'armv7l'
      @gcc_global_opts += <<~BUILD.tr("\n", ' ')
        --with-float=hard
        --with-cpu=armv7ve+neon-vfpv4
        --with-tune=cortex-a17
        --with-fpu=neon-vfpv4
      BUILD
    when 'x86_64', 'i686'
      @gcc_global_opts += <<~BUILD.tr("\n", ' ')
        --with-cpu-32=i686
        --with-cpu-64=x86-64
      BUILD
    end

    @languages = 'ada,c,c++,d,fortran,go,jit,lto,m2,objc,obj-c++'

    # Set ccache sloppiness as per
    # https://wiki.archlinux.org/index.php/Ccache#Sloppiness
    system 'ccache --set-config=sloppiness=file_macro,locale,time_macros'

    # Prefix ccache to path.
    @path = "#{CREW_LIB_PREFIX}/ccache/bin:#{CREW_PREFIX}/bin:/usr/bin:/bin"

    # Install prereqs using the standard gcc method so they can be
    # linked statically.
    # system './contrib/download_prerequisites'

    FileUtils.mkdir_p 'objdir/gcc/.deps'

    Dir.chdir('objdir') do
      # LIBRARY_PATH=#{CREW_LIB_PREFIX} needed for x86_64 to avoid:
      # /usr/local/bin/ld: cannot find crti.o: No such file or directory
      # /usr/local/bin/ld: cannot find /usr/lib64/libc_nonshared.a
      configure_env = { LIBRARY_PATH: CREW_LIB_PREFIX, PATH: @path }.transform_keys(&:to_s)

      system configure_env, <<~BUILD.chomp
        ../configure #{@gcc_global_opts.chomp} \
          --enable-languages=#{@languages} \
          --program-suffix="-#{@gcc_version}"
      BUILD

      system configure_env, 'make || make -j1'
    end
  end

  # preserve for check, skip check for current version
  def self.check
    # Dir.chdir('objdir') do
    #  system "make -k check -j#{CREW_NPROC} || true"
    #  system '../contrib/test_summary'
    # end
  end

  def self.install
    gcc_arch = `objdir/gcc/xgcc -dumpmachine`.chomp
    gcc_dir = "gcc/#{gcc_arch}/#{@gcc_version}"
    gcc_libdir = "#{CREW_DEST_LIB_PREFIX}/#{gcc_dir}"

    make_env =
      {
        LIBRARY_PATH: CREW_LIB_PREFIX,
                PATH: @path,
             DESTDIR: CREW_DEST_DIR
      }.transform_keys(&:to_s)

    Dir.chdir('objdir') do
      # gcc-libs install
      system make_env, "make -C #{CREW_TGT}/libgcc DESTDIR=#{CREW_DEST_DIR} install-shared"

      gcc_libs = %w[libatomic libgfortran libgo libgomp libitm
                    libquadmath libsanitizer/asan libsanitizer/lsan libsanitizer/ubsan
                    libsanitizer/tsan libstdc++-v3/src libvtv]
      gcc_libs.each do |lib|
        system make_env, "make -C #{CREW_TGT}/#{lib} install-toolexeclibLTLIBRARIES"
      end

      system make_env, "make -C #{CREW_TGT}/libobjc install-libs"
      system make_env, "make -C #{CREW_TGT}/libstdc++-v3/po install"
      system make_env, "make -C #{CREW_TGT}/libphobos install"

      # gcc_libs_info
      %w[libgomp libitm libquadmath].each do |lib|
        system make_env, "make -C #{CREW_TGT}/#{lib} install-info"
      end

      system make_env, "make install-strip"

      # gcc-non-lib install
      system make_env, "make -C gcc install-driver install-cpp install-gcc-ar \
        c++.install-common install-headers install-plugin install-lto-wrapper"

      %w[gcov gcov-tool].each do |gcov_bin|
        FileUtils.install "gcc/#{gcov_bin}", "#{CREW_DEST_PREFIX}/bin/#{gcov_bin}-#{@gcc_version}", mode: 0o755
      end

      FileUtils.mkdir_p gcc_libdir

      %w[cc1 cc1plus collect2 lto1].each do |lib|
        FileUtils.install "gcc/#{lib}", "#{gcc_libdir}/", mode: 0o755
      end

      system make_env, "make -C #{CREW_TGT}/libgcc install"

      %w[src include libsupc++ python].each do |lib|
        system make_env, "make -C #{CREW_TGT}/libstdc++-v3/#{lib} install"
      end

      system make_env, "make install-libcc1"

      # http://www.linuxfromscratch.org/lfs/view/development/chapter06/gcc.html#contents-gcc
      # move a misplaced file
      # The installation stage puts some files used by gdb under the /usr/local/lib(64) directory.
      # This generates spurious error messages when performing ldconfig. This command moves the files to another location.
      FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/share/gdb/auto-load/usr/lib"
      FileUtils.mv Dir["#{CREW_DEST_LIB_PREFIX}/*gdb.py"], "#{CREW_DEST_PREFIX}/share/gdb/auto-load/usr/lib/"

      system make_env, "make install-fixincludes"
      system make_env, "make -C gcc install-mkheaders"

      system make_env, "make -C lto-plugin install"

      system make_env, "make -C #{CREW_TGT}/libgomp install-nodist_libsubincludeHEADERS"
      system make_env, "make -C #{CREW_TGT}/libgomp install-nodist_toolexeclibHEADERS"
      system make_env, "make -C #{CREW_TGT}/libitm install-nodist_toolexeclibHEADERS"
      system make_env, "make -C #{CREW_TGT}/libquadmath install-nodist_libsubincludeHEADERS"
      system make_env, "make -C #{CREW_TGT}/libsanitizer install-nodist_sanincludeHEADERS"
      system make_env, "make -C #{CREW_TGT}/libsanitizer install-nodist_toolexeclibHEADERS"

      Dir["#{CREW_TGT}/libsanitizer/{a,t,l}san"].each do |dir|
        # This might fail on i686
        system make_env, "make -C #{dir} install-nodist_toolexeclibHEADERS"
      end

      # libiberty is installed from binutils
      # system "env LD_LIBRARY_PATH=#{CREW_LIB_PREFIX} \
      #      LIBRARY_PATH=#{CREW_LIB_PREFIX} PATH=#{@path} \
      #      make -C libiberty DESTDIR=#{CREW_DEST_DIR} install"
      # install -m644 libiberty/pic/libiberty.a "#{CREW_DEST_PREFIX}/lib"

      system make_env, "make -C gcc install-man install-info"

      system make_env, "make -C libcpp install"
      system make_env, "make -C gcc install-po"

      # install the libstdc++ man pages
      system make_env, "make -C #{CREW_TGT}/libstdc++-v3/doc doc-install-man"

      # byte-compile python libraries
      system "python3 -m compileall #{CREW_DEST_PREFIX}/share/gcc-#{@gcc_version}/"
      system "python3 -O -m compileall #{CREW_DEST_PREFIX}/share/gcc-#{@gcc_version}"
    end

    Dir.chdir "#{CREW_DEST_MAN_PREFIX}/man1" do
      Dir["*-#{@gcc_version}.1*"].each do |f|
        basefile = f.gsub("-#{@gcc_version}", '')
        FileUtils.ln_sf f, basefile, verbose: true
      end
    end

    Dir.chdir "#{CREW_DEST_PREFIX}/bin/" do
      Dir["#{gcc_arch}-*-#{@gcc_version}"].each do |f|
        basefile_nover = f.delete_suffix("-#{@gcc_version}")

        basefile_noarch = f.delete_prefix("#{gcc_arch}-")
        FileUtils.ln_sf f, basefile_noarch, verbose: true

        basefile_noarch_nover = basefile_nover.delete_prefix("#{gcc_arch}-")
        FileUtils.ln_sf f, basefile_noarch_nover, verbose: true

        basefile_noarch_nover_nogcc = basefile_noarch_nover.delete_prefix('gcc-')
        FileUtils.ln_sf f, "#{gcc_arch}-#{basefile_noarch_nover_nogcc}", verbose: true
      end

      Dir["*-#{@gcc_version}"].each do |f|
        basefile_nover = f.delete_suffix("-#{@gcc_version}")
        FileUtils.ln_sf f, basefile_nover, verbose: true
      end

      # many packages expect this symlink
      FileUtils.ln_sf "gcc-#{@gcc_version}", 'cc'
    end

    # make sure current version of gcc LTO plugin for Gold linker is installed.
    FileUtils.mkdir_p "#{CREW_DEST_LIB_PREFIX}/bfd-plugins/"
    FileUtils.ln_sf "#{CREW_PREFIX}/libexec/#{gcc_dir}/liblto_plugin.so", "#{CREW_DEST_LIB_PREFIX}/bfd-plugins/"

    # binutils makes a symlink here, but just in case it isn't there.
    if ARCH_LIB == 'lib64'
      FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/lib/bfd-plugins/"
      FileUtils.ln_sf "#{CREW_PREFIX}/libexec/#{gcc_dir}/liblto_plugin.so", "#{CREW_DEST_PREFIX}/lib/bfd-plugins/"
    end

    File.write "#{CREW_DEST_PREFIX}/bin/c99", @C99, perm: 0o755
    File.write "#{CREW_DEST_PREFIX}/bin/c89", @C89, perm: 0o755
  end
end
