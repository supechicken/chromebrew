require 'package'

class Jdk11 < Package
  description 'The JDK is a development environment for building applications, applets, and components using the Java programming language.'
  homepage 'https://www.oracle.com/java/technologies/javase/javase-jdk11-downloads.html'
  version '11.x'
  license 'Oracle-BCLA-JavaSE'
  compatibility 'x86_64'

  no_compile_needed
  no_patchelf

  def self.preflight
    if File.exist?("#{CREW_PREFIX}/bin/java")
      jdkver_str = `#{CREW_PREFIX}/bin/java -version 2>&1`
      is_openjdk = jdkver_str.include?('openjdk')
      jdkver     = jdkver_str[/version "(.+?)"/, 1]
      majver     = jdkver.split('.')[0]
      majver     = '8' if majver == '1'
      pkg_suffix = (is_openjdk) ? 'openjdk' : 'jdk'

      unless majver == self.name[-1]
        puts "Package #{pkg_suffix}#{majver} already installed.".lightgreen
        warn "Run `crew remove #{pkg_suffix}#{majver} && crew install #{self.name}` to install this version of JDK.".yellow
        return false
      end
    end

    jdk_bin = Dir["#{HOME}/Downloads/jdk-11.*-linux-x64.tar.gz"][0]

    unless jdk_bin
      abort <<~EOT.orange

        Oracle now requires an account to download the JDK.

        You must login at https://login.oracle.com/mysso/signon.jsp and then visit:
        https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html

        Download the JDK for your architecture to #{HOME}/Downloads to continue.

      EOT
    end

    source_url 'file://' + jdk_bin
    source_sha256 'SKIP'
  end

  def self.install
    jdk_dir = "#{CREW_DEST_PREFIX}/share/jdk8"
    FileUtils.mkdir_p [jdk_dir, "#{CREW_DEST_PREFIX}/bin", CREW_DEST_MAN_PREFIX]

    Dir.chdir Dir['jdk*'][0] do
      FileUtils.rm_f 'lib/src.zip'
      FileUtils.cp_r Dir['*'], jdk_dir
    end

    Dir["#{jdk_dir}/bin/*"].each do |path|
      filename = File.basename(path)
      FileUtils.ln_s "#{CREW_PREFIX}/share/jdk8/bin/#{filename}", "#{CREW_DEST_PREFIX}/bin/#{filename}"
    end

    FileUtils.rm ["#{jdk11_dir}/man/man1/kinit.1", "#{jdk11_dir}/man/man1/klist.1"] # conflicts with krb5 package
    FileUtils.mv Dir["#{jdk_dir}/man/*"], CREW_DEST_MAN_PREFIX
  end

  def self.postinstall
    jdk_bin = Dir["#{HOME}/Downloads/jdk-8u*-linux-#{jdk_arch}.tar.gz"][0]
    FileUtils.rm_f jdk_bin if jdk_bin
  end
end
