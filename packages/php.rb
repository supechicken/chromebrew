require 'package'

class Php < Package
  description 'PHP is a popular general-purpose scripting language that is especially suited to web development.'
  homepage 'https://www.php.net'
  license 'PHP-3.01'
  compatibility 'all'

  @avail_php_ver = Dir["#{CREW_PACKAGES_PATH}/php?*.rb"].map do |pkgFile|
    php_majver = pkgFile[/php(\d+).rb/, 1].to_i
    pkg        = Package.load_package(pkgFile)

    [php_majver, pkg.version]
  end.sort_by do |(php_majver, _)|
    php_majver
  end.to_h

  version "#{@avail_php_ver.values[0]}-#{@avail_php_ver.values[-1]}"

  is_fake

  def self.preflight
    if ARGV.include?('install')
      php_exec = File.join(CREW_PREFIX, 'bin', 'php')

      if File.exist?(php_exec)
        full_ver                = `#{php_exec} -v`[/^PHP ([^\s]+)/, 1]
        major_ver, minor_ver, _ = full_ver.split('.', 3)

        abort <<~EOT.yellow

          PHP version #{full_ver} installed.

          Run "crew remove php#{major_ver}#{minor_ver}; crew install php" to install another version of PHP
        EOT
      end

      options = @avail_php_ver.map {|majver, ver| { value: "php#{majver}", description: "PHP #{ver}" } }
      depends_on Selector.new(options).show_prompt
    end
  end
end