require 'json'
require_relative 'color'

class Pip < Integration
  @prefix = 'py3'

  def self.load_installed_meta
    @installed = JSON.parse(`pip inspect -qq`, symbolize_names: true)[:installed]
  end

  def self.get_package_meta (pkgName)
    unless installed?(pkgName)
      pkgInfo = JSON.parse(`curl -LSs https://pypi.org/pypi/#{pkgName}/json`, symbolize_names: true)[:info]
    else
      pkgInfo = @installed.select {|pkg| pkg[:metadata][:name] == pkgName } [0][:metadata]
    end

    # use "summary" if "description" is too long
    description = if pkgInfo[:description] && pkgInfo[:description].count("\n") > 2
                    pkgInfo[:summary]
                  else
                    pkgInfo[:description] || ''
                  end

    return {
      description:,
      homepage: pkgInfo[:home_page],
      license: pkgInfo[:license],
      version: pkgInfo[:version]
    }.transform_values(&:chomp)
  end

  def self.get_upgradable_list
    @upgradable ||= `pip list --outdated`.lines(chomp: true)[2..].filter_map do |pkg|
      pkgName, currentVer, latestVer, _ = pkg.split(/\s+/, 4)

      # don't check for updates if crew version exists
      if File.file?( File.join(CREW_PACKAGES_PATH, "#{convert_to_crew(pkgName)}.rb") )
        [pkgName, [currentVer, latestVer]]
      else
        next
      end
    end.to_h
  end

  def self.installed?(pkgName) = @installed.any? {|pkg| pkg[:metadata][:name] == pkgName }
