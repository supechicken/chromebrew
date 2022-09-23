# runtime_const.rb: Defines runtime constants used in different parts of crew

CREW_VERSION = '1.25.4'

# Glibc version can be found from the output of libc.so.6
LIBC_VERSION = `/#{ARCH_LIB}/libc.so.6`[/Gentoo ([^-]+)/, 1]
MUSL_LIBC_VERSION = `#{CREW_MUSL_PREFIX}/lib/libc.so 2>&1 >/dev/null`[/\bVersion\s+\K\S+/] || nil

if CREW_PREFIX == '/usr/local'
  CREW_BUILD_FROM_SOURCE = ENV.fetch('CREW_BUILD_FROM_SOURCE', nil)
else
  CREW_BUILD_FROM_SOURCE = 1
end

# File.join ensures a trailing slash if one does not exist.
CREW_CACHE_DIR = if ENV['CREW_CACHE_DIR'].to_s.empty?
                   File.join("#{HOME}/.cache/crewcache", '')
                 else
                   File.join(ENV.fetch('CREW_CACHE_DIR', nil), '')
                 end

FileUtils.mkdir_p CREW_CACHE_DIR

# Set CREW_NPROC from environment variable or `nproc`
CREW_NPROC = ENV['CREW_NPROC'].to_s.empty? ? `nproc`.chomp : ENV.fetch('CREW_NPROC', nil)

# Set following as boolean if environment variables exist.
CREW_CACHE_ENABLED                   = ENV['CREW_CACHE_ENABLED'].eql?(1)
CREW_CONFLICTS_ONLY_ADVISORY         = ENV['CREW_CONFLICTS_ONLY_ADVISORY'].eql?(1) # or use conflicts_ok
CREW_DISABLE_ENV_OPTIONS             = ENV['CREW_DISABLE_ENV_OPTIONS'].eql?(1) # or use no_env_options
CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY = ENV['CREW_FHS_NONCOMPLIANCE_ONLY_ADVISORY'].eql?(1) # or use no_fhs
CREW_LA_RENAME_ENABLED               = ENV['CREW_LA_RENAME_ENABLED'].eql?(1)
CREW_NOT_COMPRESS                    = ENV['CREW_NOT_COMPRESS'].eql?(1) # or use no_compress
CREW_NOT_STRIP                       = ENV['CREW_NOT_STRIP'].eql?(1) # or use no_strip
CREW_NOT_SHRINK_ARCHIVE              = ENV['CREW_NOT_SHRINK_ARCHIVE'].eql?(1) # or use no_shrink

# Set testing constants from environment variables
CREW_TESTING_BRANCH = ENV.fetch('CREW_TESTING_BRANCH', nil)
CREW_TESTING_REPO   = ENV.fetch('CREW_TESTING_REPO', nil)

CREW_TESTING = CREW_TESTING_BRANCH.to_s.empty? || CREW_TESTING_REPO.to_s.empty? ? '0' : ENV.fetch('CREW_TESTING', nil)

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
CREW_DOWNLOADER = ENV['CREW_DOWNLOADER'].to_s.empty? ? nil : ENV.fetch('CREW_DOWNLOADER', nil)

# Downloader maximum retry count
CREW_DOWNLOADER_RETRY = ENV['CREW_DOWNLOADER_RETRY'].to_s.empty? ? 3 : ENV['CREW_DOWNLOADER_RETRY'].to_i
# show download progress bar or not (only applied when using the default ruby downloader)
CREW_HIDE_PROGBAR = ENV['CREW_HIDE_PROGBAR'].eql?('1')

# set certificate file location for lib/downloader.rb
SSL_CERT_FILE = if ENV['SSL_CERT_FILE'].to_s.empty? || !File.exist?(ENV.fetch('SSL_CERT_FILE', nil))
                  if File.exist?("#{CREW_PREFIX}/etc/ssl/certs/ca-certificates.crt")
                    "#{CREW_PREFIX}/etc/ssl/certs/ca-certificates.crt"
                  else
                    '/etc/ssl/certs/ca-certificates.crt'
                  end
                else
                  ENV.fetch('SSL_CERT_FILE', nil)
                end
SSL_CERT_DIR = if ENV['SSL_CERT_DIR'].to_s.empty? || !Dir.exist?(ENV.fetch('SSL_CERT_DIR', nil))
                 if Dir.exist?("#{CREW_PREFIX}/etc/ssl/certs")
                   "#{CREW_PREFIX}/etc/ssl/certs"
                 else
                   '/etc/ssl/certs'
                 end
               else
                 ENV.fetch('SSL_CERT_DIR', nil)
               end

case ARCH
when 'aarch64', 'armv7l'
  CREW_TGT = 'armv7l-cros-linux-gnueabihf'
  CREW_BUILD = 'armv7l-cros-linux-gnueabihf'
when 'i686'
  CREW_TGT = 'i686-cros-linux-gnu'
  CREW_BUILD = 'i686-cros-linux-gnu'
when 'x86_64'
  CREW_TGT = 'x86_64-cros-linux-gnu'
  CREW_BUILD = 'x86_64-cros-linux-gnu'
end

CREW_LINKER = ENV.fetch('CREW_LINKER', 'mold')
CREW_LINKER_FLAGS = ENV.fetch('CREW_LINKER_FLAGS', nil)

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

# Use ninja or samurai
CREW_NINJA = ENV.fetch('CREW_NINJA', 'samu')

CREW_ESSENTIAL_FILES = (
                         `LD_TRACE_LOADED_OBJECTS=1 #{CREW_PREFIX}/bin/ruby`.scan(/\t([^ ]+)/).flatten +
                         `LD_TRACE_LOADED_OBJECTS=1 #{CREW_PREFIX}/bin/rsync`.scan(/\t([^ ]+)/).flatten +
                         %w[libzstd.so.1 libstdc++.so.6]
                       ).uniq
