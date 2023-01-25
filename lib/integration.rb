class Integration
  def self.convert_to_crew   (pkgName)      = "#{@prefix}_#{pkgName.tr('-', '_')}"
  def self.convert_to_pkgmgr (crew_pkgName) = crew_pkgName.delete_prefix("#{@prefix}_").tr('_', '-')
end