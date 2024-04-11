require 'fileutils'
require 'package'

class Autotools < Package
  property :configure_options, :pre_configure_options, :install_extras

  def self.build
    bootstrap_env = { 'NOCONFIGURE' => '1' }
    mold          = CREW_LINKER.eql?('mold') ? %w[mold -run] : []

    unless File.file?('Makefile') && CREW_CACHE_BUILD
      puts "Additional configure_options being used: #{@pre_configure_options.nil? ? '<no pre_configure_options>' : @pre_configure_options} #{@configure_options.nil? ? '<no configure_options>' : @configure_options}".orange

      unless File.exist?('configure')
        # call bootstrap script if ./configure not exist
        if File.exist?('autogen.sh')
          FileUtils.chmod(0o755, 'autogen.sh')
          system bootstrap_env, './autogen.sh --no-configure || ./autogen.sh'
        elsif File.exist?('bootstrap')
          FileUtils.chmod(0o755, 'bootstrap')
          system bootstrap_env, './bootstrap --no-configure || ./bootstrap'
        else
          # Run autoreconf if no bootstrap script available
          system 'autoreconf -fiv'
        end
      end

      abort 'Error: configure script not found!'.lightred unless File.file?('configure')

      FileUtils.chmod(0o755, 'configure')

      warn 'Fixing file command path'.orange
      system 'sed', '-i', "s,/usr/bin/file,#{CREW_PREFIX}/bin/file,g", 'configure'

      system @pre_configure_options, @mold_linker_prefix_cmd + "./configure #{CREW_OPTIONS} #{@configure_options}"
    end

    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
    @install_extras.call if @install_extras
  end

  def self.check
    return unless @run_tests

    warn 'Testing with make check.'.orange
    system 'make', 'check'
  end
end
