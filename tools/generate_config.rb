#!/usr/bin/env ruby
# crew_generate_config.rb: Generate configuration file for Chromebrew
require 'json'
require 'optparse'

### essential constants with default values ###

ARCH_ACTUAL = `uname -m`.chomp
# This helps with virtualized builds on aarch64 machines
# which report armv8l when linux32 is run.
ARCH = ARCH_ACTUAL == 'armv8l' ? 'armv7l' : ARCH_ACTUAL
HOME = Dir.home
CREW_PREFIX = '/usr/local'

### override essential constants if specified in cmdline params ###
OptionParser.new do |opts|
  opts.banner = <<~EOT
    crew_generate_config.rb: Generate configuration file for Chromebrew

    Usage: crew_generate_config.rb [options]

  EOT

  opts.on('--prefix=PREFIX', 'Use custom Chromebrew installation prefix') do |prefix|
    Object.remove_const(:CREW_PREFIX)
    CREW_PREFIX = prefix
  end

  opts.on('--arch=ARCH', 'Use custom device architecture') do |arch|
    Object.remove_const(:ARCH)
    ARCH = arch
  end

  opts.on('--home=HOME', 'Use custom home directory path') do |home|
    Object.remove_const(:HOME)
    HOME = home
  end

  opts.on('-h', '--help', 'Show this message') { puts opts; exit 0 }
end.parse!

### reminding constants (generated according to the essential constants above) ###

# Allow for edge case of i686 install on a x86_64 host before linux32 is
# downloaded, e.g. in a docker container.
CREW_LIB_SUFFIX = (ARCH == 'x86_64') && Dir.exist?('/lib64') ?  '64' : ''
ARCH_LIB        = 'lib' + CREW_LIB_SUFFIX

CREW_LIB_PREFIX      = "#{CREW_PREFIX}/#{ARCH_LIB}"
CREW_MAN_PREFIX      = "#{CREW_PREFIX}/share/man"
CREW_LIB_PATH        = "#{CREW_PREFIX}/lib/crew/"
CREW_PACKAGES_PATH   = "#{CREW_LIB_PATH}packages/"
CREW_CONFIG_PATH     = "#{CREW_PREFIX}/etc/crew/"
CREW_META_PATH       = "#{CREW_CONFIG_PATH}meta/"
CREW_BREW_DIR        = "#{CREW_PREFIX}/tmp/crew/"
CREW_DEST_DIR        = "#{CREW_BREW_DIR}dest"
CREW_DEST_PREFIX     = CREW_DEST_DIR + CREW_PREFIX
CREW_DEST_LIB_PREFIX = CREW_DEST_DIR + CREW_LIB_PREFIX
CREW_DEST_MAN_PREFIX = CREW_DEST_DIR + CREW_MAN_PREFIX
 
# Put musl build dir under CREW_PREFIX/share/musl to avoid FHS incompatibility
CREW_MUSL_PREFIX      = "#{CREW_PREFIX}/share/musl"
CREW_DEST_MUSL_PREFIX = CREW_DEST_DIR + CREW_MUSL_PREFIX

CREW_DEST_HOME = CREW_DEST_DIR + HOME

### write to config ###

# get all constants defined above
config = Object.constants.select do |const|
  const.to_s =~ /^CREW_/ or %i[HOME ARCH_LIB ARCH ARCH_ACTUAL].include?(const)
end.map do |crew_const|
  value = Object.const_get(crew_const)
  [crew_const, value]
end.to_h

# write to config
config_file = File.join(CREW_CONFIG_PATH, 'config.json')
json = JSON.pretty_generate(config)

FileUtils.mkdir_p CREW_CONFIG_PATH
File.write(config_file, json)

puts "Configuration file saved in #{config_file}."