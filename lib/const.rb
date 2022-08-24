# Defines common constants used in different parts of crew

CREW_VERSION = '1.25.3'

ARCH_ACTUAL = `uname -m`.chomp
# This helps with virtualized builds on aarch64 machines
# which report armv8l when linux32 is run.
ARCH = ARCH_ACTUAL.sub('armv8l', 'armv7l')

# Allow for edge case of i686 install on a x86_64 host before linux32 is
# downloaded, e.g. in a docker container.
CREW_LIB_SUFFIX = ( ARCH.eql?('x86_64') and Dir.exist?('/lib64') ) ? '64' : ''
ARCH_LIB        = "lib#{CREW_LIB_SUFFIX}"

# Glibc version can be found from the output of libc.so.6
LIBC_VERSION = `/#{ARCH_LIB}/libc.so.6`[/Gentoo ([^-]+)/, 1]

if ENV.fetch('CREW_PREFIX', '/usr/local') == '/usr/local'
  CREW_BUILD_FROM_SOURCE = ENV['CREW_BUILD_FROM_SOURCE'].eql?('1')
  CREW_PREFIX            = '/usr/local'
  HOME                   = Dir.home
else
  CREW_BUILD_FROM_SOURCE = true
  CREW_PREFIX            = ENV['CREW_PREFIX']
  HOME                   = File.join(CREW_PREFIX, Dir.home)
end

TMPDIR = ENV.fetch( 'TMPDIR', File.join(CREW_PREFIX, 'tmp/') )

# constants based on CREW_PREFIX
CREW_LIB_PREFIX      = File.join(CREW_PREFIX, ARCH_LIB)
CREW_MAN_PREFIX      = File.join(CREW_PREFIX, 'share/man/')
CREW_LIB_PATH        = File.join(CREW_PREFIX, 'lib/crew/')
CREW_PACKAGES_PATH   = File.join(CREW_LIB_PATH, 'packages/')
CREW_CONFIG_PATH     = File.join(CREW_PREFIX, 'etc/crew/')
CREW_META_PATH       = File.join(CREW_CONFIG_PATH, 'meta/')
CREW_BREW_DIR        = File.join(CREW_PREFIX, 'tmp/crew/')
CREW_DEST_DIR        = File.join(CREW_BREW_DIR, 'dest/')
CREW_DEST_PREFIX     = File.join(CREW_DEST_DIR, CREW_PREFIX)
CREW_DEST_LIB_PREFIX = File.join(CREW_DEST_DIR, CREW_LIB_PREFIX)
CREW_DEST_MAN_PREFIX = File.join(CREW_DEST_DIR, CREW_MAN_PREFIX)

# Put musl build dir under CREW_PREFIX/share/musl to avoid FHS incompatibility
     CREW_MUSL_PREFIX = File.join(CREW_PREFIX, '/share/musl/')
CREW_DEST_MUSL_PREFIX = File.join(CREW_DEST_DIR, CREW_MUSL_PREFIX)
    MUSL_LIBC_VERSION = `#{CREW_MUSL_PREFIX}/lib/libc.so 2>&1`[/\bVersion\s+\K\S+/] || nil

CREW_DEST_HOME = File.join(CREW_DEST_DIR, HOME)
CREW_CACHE_DIR = ENV.fetch( 'CREW_CACHE_DIR', File.join(TMPDIR, 'crew/cache/') )

FileUtils.mkdir_p CREW_CACHE_DIR 

# Set CREW_NPROC from environment variable or `nproc`
CREW_NPROC = ENV.fetch('CREW_NPROC', `nproc`.chomp)

# Set following as boolean if environment variables exist.
CREW_CACHE_ENABLED                   = ENV['CREW_CACHE_ENABLED'].eql?('1')
CREW_CONFLICTS_ONLY_ADVISORY         = ENV['CREW_CONFLICTS_ONLY_ADVISORY'].eql?('1') # or use conflicts_ok
CREW_DISABLE_ENV_OPTIONS             = ENV['CREW_DISABLE_ENV_OPTIONS'].eql?('1') # or use no_env_options
CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY = ENV['CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY'].eql?('1') # or use no_fhs
CREW_LA_RENAME_ENABLED               = ENV['CREW_LA_RENAME_ENABLED'].eql?('1')
CREW_NOT_COMPRESS                    = ENV['CREW_NOT_COMPRESS'].eql?('1')
CREW_NOT_STRIP                       = ENV['CREW_NOT_STRIP'].eql?('1')
CREW_NOT_SHRINK_ARCHIVE              = ENV['CREW_NOT_SHRINK_ARCHIVE'].eql?('1')

# Set testing constants from environment variables
CREW_TESTING_BRANCH = ENV.fetch('CREW_TESTING_BRANCH', nil)
CREW_TESTING_REPO   = ENV.fetch('CREW_TESTING_REPO', nil)

CREW_TESTING = ( CREW_TESTING_BRANCH && CREW_TESTING_REPO && ENV['CREW_TESTING'].eql?('1') )

USER = `whoami`.chomp

CHROMEOS_RELEASE = if File.exist?('/etc/lsb-release')
                     File.read('/etc/lsb-release')[/CHROMEOS_RELEASE_CHROME_MILESTONE=(.+)/, 1]
                   else
                     # newer version of Chrome OS exports info to env by default
                     ENV.fetch('CHROMEOS_RELEASE_CHROME_MILESTONE', nil)
                   end

# If CREW_USE_CURL environment variable exists use curl in lieu of net/http.
CREW_USE_CURL = ENV['CREW_USE_CURL'].eql?('1')

# Use an external downloader instead of net/http if CREW_DOWNLOADER is set, see lib/downloader.rb for more info
# About the format of the CREW_DOWNLOADER variable, see line 130-133 in lib/downloader.rb
CREW_DOWNLOADER = ENV.fetch('CREW_DOWNLOADER', nil)

# Downloader maximum retry count
CREW_DOWNLOADER_RETRY = ENV.fetch('CREW_DOWNLOADER_RETRY', '3').to_i
# show download progress bar or not (only applied when using the default ruby downloader)
CREW_HIDE_PROGBAR = ENV['CREW_HIDE_PROGBAR'].eql?('1')

# set certificate file location for lib/downloader.rb
SSL_CERT_FILE = unless File.exist?(ENV['SSL_CERT_FILE'])
                  if File.exist?("#{CREW_PREFIX}/etc/ssl/certs/ca-certificates.crt")
                    File.join(CREW_PREFIX, 'etc/ssl/certs/ca-certificates.crt')
                  else
                    '/etc/ssl/certs/ca-certificates.crt'
                  end
                else
                  ENV.fetch('SSL_CERT_FILE', nil)
                end

SSL_CERT_DIR = unless Dir.exist?(ENV['SSL_CERT_DIR'])
                 if Dir.exist?("#{CREW_PREFIX}/etc/ssl/certs/")
                   File.join(CREW_PREFIX, 'etc/ssl/certs/')
                 else
                   '/etc/ssl/certs'
                 end
               else
                 ENV.fetch('SSL_CERT_DIR', nil)
               end

case ARCH
when 'aarch64', 'armv7l'
  CREW_TGT   = 'armv7l-cros-linux-gnueabihf'
  CREW_BUILD = 'armv7l-cros-linux-gnueabihf'
when 'i686'
  CREW_TGT   = 'i686-cros-linux-gnu'
  CREW_BUILD = 'i686-cros-linux-gnu'
when 'x86_64'
  CREW_TGT   = 'x86_64-cros-linux-gnu'
  CREW_BUILD = 'x86_64-cros-linux-gnu'
end

CREW_LINKER       = ENV.fetch('CREW_LINKER', 'mold')
CREW_LINKER_FLAGS = ENV.fetch('CREW_LINKER_FLAGS', nil)

CREW_CORE_FLAGS           = "-O2 -pipe -ffat-lto-objects -fPIC -fuse-ld=#{CREW_LINKER} #{CREW_LINKER_FLAGS}"
CREW_COMMON_FLAGS         = "#{CREW_CORE_FLAGS} -flto"
CREW_COMMON_FNO_LTO_FLAGS = "#{CREW_CORE_FLAGS} -fno-lto"
CREW_LDFLAGS              = "-flto #{CREW_LINKER_FLAGS}"
CREW_FNO_LTO_LDFLAGS      = '-fno-lto'

CREW_ENV_OPTIONS_HASH = if CREW_DISABLE_ENV_OPTIONS
                          { 'CREW_DISABLE_ENV_OPTIONS' => '1' }
                        else
                          {
                            'CFLAGS'   => CREW_COMMON_FLAGS,
                            'CXXFLAGS' => CREW_COMMON_FLAGS,
                            'FCFLAGS'  => CREW_COMMON_FLAGS,
                            'FFLAGS'   => CREW_COMMON_FLAGS,
                            'LDFLAGS'  => CREW_LDFLAGS
                          }
                        end

# parse from hash to shell readable string
CREW_ENV_OPTIONS = CREW_ENV_OPTIONS_HASH.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')

CREW_ENV_FNO_LTO_OPTIONS_HASH = {
  'CFLAGS'   => CREW_COMMON_FNO_LTO_FLAGS,
  'CXXFLAGS' => CREW_COMMON_FNO_LTO_FLAGS,
  'FCFLAGS'  => CREW_COMMON_FNO_LTO_FLAGS,
  'FFLAGS'   => CREW_COMMON_FNO_LTO_FLAGS,
  'LDFLAGS'  => CREW_FNO_LTO_LDFLAGS
}
# parse from hash to shell readable string
CREW_ENV_FNO_LTO_OPTIONS = CREW_ENV_FNO_LTO_OPTIONS_HASH.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')

CREW_OPTIONS = <<~OPT.chomp
  --prefix=#{CREW_PREFIX} \
  --libdir=#{CREW_LIB_PREFIX} \
  --mandir=#{CREW_MAN_PREFIX} \
  --build=#{CREW_BUILD} \
  --host=#{CREW_TGT} \
  --target=#{CREW_TGT} \
  --program-prefix='' \
  --program-suffix=''
OPT

CREW_MESON_OPTIONS = <<~OPT.chomp
  -Dprefix=#{CREW_PREFIX} \
  -Dlibdir=#{CREW_LIB_PREFIX} \
  -Dmandir=#{CREW_MAN_PREFIX} \
  -Dbuildtype=release \
  -Db_lto=true \
  -Dstrip=true \
  -Db_pie=true \
  -Dcpp_args='#{CREW_CORE_FLAGS}' \
  -Dc_args='#{CREW_CORE_FLAGS}'
OPT

CREW_MESON_FNO_LTO_OPTIONS = <<~OPT.chomp
  -Dprefix=#{CREW_PREFIX} \
  -Dlibdir=#{CREW_LIB_PREFIX} \
  -Dmandir=#{CREW_MAN_PREFIX} \
  -Dbuildtype=release \
  -Db_lto=false \
  -Dstrip=true \
  -Db_pie=true \
  -Dcpp_args='#{CREW_CORE_FLAGS}' \
  -Dc_args='#{CREW_CORE_FLAGS}'
OPT

# Use ninja or samurai
CREW_NINJA = ENV['CREW_NINJA'].casecmp?('ninja') ? 'ninja' : 'samu'

# Cmake sometimes wants to use LIB_SUFFIX to install libs in LIB64, so specify such for x86_64
# This is often considered deprecated. See discussio at https://gitlab.kitware.com/cmake/cmake/-/issues/18640
# and also https://bugzilla.redhat.com/show_bug.cgi?id=1425064
# Let's have two CREW_CMAKE_OPTIONS since this avoids the logic in the recipe file.
CREW_CMAKE_OPTIONS = <<~OPT.chomp
  -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} \
  -DCMAKE_LIBRARY_PATH=#{CREW_LIB_PREFIX} \
  -DCMAKE_C_FLAGS='#{CREW_COMMON_FLAGS}' \
  -DCMAKE_CXX_FLAGS='#{CREW_COMMON_FLAGS}' \
  -DCMAKE_EXE_LINKER_FLAGS='#{CREW_LDFLAGS}' \
  -DCMAKE_SHARED_LINKER_FLAGS='#{CREW_LDFLAGS}' \
  -DCMAKE_STATIC_LINKER_FLAGS='#{CREW_LDFLAGS}' \
  -DCMAKE_MODULE_LINKER_FLAGS='#{CREW_LDFLAGS}' \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=TRUE \
  -DCMAKE_BUILD_TYPE=Release
OPT
CREW_CMAKE_FNO_LTO_OPTIONS = <<~OPT.chomp
  -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} \
  -DCMAKE_LIBRARY_PATH=#{CREW_LIB_PREFIX} \
  -DCMAKE_C_FLAGS='#{CREW_COMMON_FNO_LTO_FLAGS}' \
  -DCMAKE_CXX_FLAGS='#{CREW_COMMON_FNO_LTO_FLAGS}' \
  -DCMAKE_EXE_LINKER_FLAGS=#{CREW_FNO_LTO_LDFLAGS} \
  -DCMAKE_SHARED_LINKER_FLAGS=#{CREW_FNO_LTO_LDFLAGS} \
  -DCMAKE_STATIC_LINKER_FLAGS=#{CREW_FNO_LTO_LDFLAGS} \
  -DCMAKE_MODULE_LINKER_FLAGS=#{CREW_FNO_LTO_LDFLAGS} \
  -DCMAKE_BUILD_TYPE=Release
OPT

CREW_CMAKE_LIBSUFFIX_OPTIONS = "#{CREW_CMAKE_OPTIONS} -DLIB_SUFFIX=#{CREW_LIB_SUFFIX}"

PY3_SETUP_BUILD_OPTIONS          = "--executable=#{CREW_PREFIX}/bin/python3"
PY2_SETUP_BUILD_OPTIONS          = "--executable=#{CREW_PREFIX}/bin/python2"
PY_SETUP_INSTALL_OPTIONS_NO_SVEM = "--root=#{CREW_DEST_DIR} --prefix=#{CREW_PREFIX} -O2 --compile"
PY_SETUP_INSTALL_OPTIONS         = "#{PY_SETUP_INSTALL_OPTIONS_NO_SVEM} --single-version-externally-managed"
PY3_BUILD_OPTIONS                = '--wheel --no-isolation'
PY3_INSTALLER_OPTIONS            = "--destdir=#{CREW_DEST_DIR} --compile-bytecode 2 dist/*.whl"

CREW_ESSENTIAL_FILES = `set -u; LD_TRACE_LOADED_OBJECTS=1; #{CREW_PREFIX}/bin/ruby; #{CREW_PREFIX}/bin/rsync`.scan(/\t([^ ]+)/).flatten
CREW_ESSENTIAL_FILES += %w[libzstd.so.1 libstdc++.so.6]
CREW_ESSENTIAL_FILES.uniq!
