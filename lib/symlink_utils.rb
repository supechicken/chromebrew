class SymlinkUtils
  def self.to_relative(dir = CREW_DEST_DIR)
    absolute_symlinks = `find '#{dir}' -type l -printf "%P -> %l\n" | grep -- '-> /'`.scan(/^(.+?) -> (.+)$/).to_h

    absolute_symlinks.each_pair do |symlink, target|
      # only handle symlinks within CREW_PREFIX to avoid screwing up things
      next unless target.start_with?(CREW_PREFIX)

      symlink_loc   = File.absolute_path(symlink, '/')
      symlink_dir   = File.dirname(symlink_loc)
      relative_path = Pathname.new(target).relative_path_from(symlink_dir)

      warn "#{symlink_loc} -> #{relative_path}".orange
      FileUtils.ln_sf(relative_path, symlink_loc)
    end
  end
end