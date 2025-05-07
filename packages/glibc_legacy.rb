require 'package'

class Glibc_legacy < Package
  description 'The GNU C Library project provides the core libraries for GNU/Linux systems.'
  homepage 'https://www.gnu.org/software/libc/'
  version '2.23'
  license 'LGPL-2.1+, BSD, HPND, ISC, inner-net, rc, and PCRE'
  compatibility 'all'
  source_url "file:///home/chronos/user/MyFiles/Downloads/glibc-2.23.tar.xz"
  source_sha256 '94efeb00e4603c8546209cefb3e1a50a5315c86fa9b078b6fad758e187ce13e9'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '59591f27ee582de7d8849239ddbc7e5b3035d0de98a8e8be4d0fc453b5c8c842',
     armv7l: '59591f27ee582de7d8849239ddbc7e5b3035d0de98a8e8be4d0fc453b5c8c842',
       i686: '8165321db2ed13ab4ba8242837314c2c508e7bd9eea5bd346fa3078cd3f86492',
     x86_64: '0846298a3e6c47f83572f4bc7936a2b2e0e2036d86e73b8fe9a56480e50e52b0'
  })

  depends_on 'gawk' => :build
  depends_on 'filecmd' # L Fixes creating symlinks on a fresh install.
  depends_on 'libidn2' => :build
  depends_on 'llvm' => :build
  depends_on 'texinfo' => :build
  depends_on 'patchelf' # L
  depends_on 'glibc' # R

  no_env_options
  no_shrink

  def self.build
    build_env = {
      CFLAGS:   "-O3 -pipe -fPIC -fno-lto",
      CXXFLAGS: "-O3 -pipe -fPIC -fno-lto",
      LDFLAGS:  '-fno-lto'
    }

    config_opts = %W[
      --prefix=#{CREW_LEGACY_GLIBC_PREFIX}
      --libdir=#{CREW_LEGACY_GLIBC_PREFIX}
      --libexecdir=#{CREW_LEGACY_GLIBC_PREFIX}/libexec
      --mandir=#{CREW_LEGACY_GLIBC_PREFIX}/man
      --with-headers=#{CREW_PREFIX}/include
      --with-bugurl=https://github.com/chromebrew/chromebrew/issues/new
      --enable-bind-now
      --enable-fortify-source
      --enable-kernel=3.2
      --enable-shared
      --disable-nscd
      --disable-profile
      --disable-sanity-checks
      --disable-werror
      --without-cvs
      --without-selinux
    ]

    config_opts << '--enable-cet' unless ARCH == 'i686'

    FileUtils.mkdir_p 'builddir'
    Dir.chdir('builddir') do
      File.write 'configparms', <<~EOF
        slibdir=#{CREW_LEGACY_GLIBC_PREFIX}
        rtlddir=#{CREW_LEGACY_GLIBC_PREFIX}
        sbindir=#{CREW_LEGACY_GLIBC_PREFIX}
        rootsbindir=#{CREW_LEGACY_GLIBC_PREFIX}
      EOF

      system build_env.transform_keys(&:to_s), '../configure', *config_opts
      system "mold -run make PARALLELMFLAGS='-j #{CREW_NPROC}'"
    end
  end

  def self.install
    system "make DESTDIR=#{CREW_DEST_DIR} install", chdir: 'builddir'
  end
end
