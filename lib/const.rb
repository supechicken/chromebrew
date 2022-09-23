# const.rb: Load constants from different files
require 'json'
require 'yaml'
require_relative 'color'

# import config file (in #{CREW_PREFIX}/etc/crew/config.json)
config_file = File.expand_path('../../../etc/crew/config.json', __dir__)

unless File.exist?(config_file)
  # generate a new one if not exist
  warn 'Configuration file does not exist! A new one will be generated.'.yellow
  system File.join(__dir__, '../bin/crew_generate_config')
end

JSON.load_file(config_file).each_pair do |name, value|
  value = eval(value.inspect.sub('\#{', '#{')) # resolve variables in string
  Object.const_set(name, value)
end

# import runtime constants (in lib/runtime_const.rb)
require_relative 'runtime_const'

# import build constants (in etc/build_const.yaml)
YAML.load_file(File.expand_path('../etc/build_const.yaml', __dir__)).each_pair do |name, value|
  value = eval(value.inspect.sub('\#{', '#{')) # resolve variables in string
  Object.const_get(name, value)
end