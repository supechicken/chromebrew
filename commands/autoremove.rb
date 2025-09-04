require_relative '../lib/convenience_functions'
require_relative '../lib/package_utils'

class Command
  def self.autoremove
    device_json    = ConvenienceFunctions.load_symbolized_json
    redundant_deps = []

    device_json[:installed_packages].each do |pkg|
      # Exclude manually installed (non-dependency) packages
      next if pkg[:is_manual_install]

      # Add package to redundant list if no other installed package depends on it
      redundant_deps << pkg[:name] if PackageUtils.reverse_dependency_lookup(pkg[:name], installed: true).any?
    end

    p redundant_deps
  end
end
