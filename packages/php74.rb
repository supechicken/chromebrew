require 'package'

class Php74 < Package
  description 'PHP is a popular general-purpose scripting language that is especially suited to web development.'
  homepage 'http://www.php.net/'
  @_ver = '7.4.32'
  version @_ver
  license 'PHP-3.01'
  compatibility 'all'
  source_url "https://www.php.net/distributions/php-#{@_ver}.tar.xz"
  source_sha256 '323332c991e8ef30b1d219cb10f5e30f11b5f319ce4c6642a5470d75ade7864a'

  binary_url({
  })
  binary_sha256({
  })

  depends_on 'aspell_en'
  depends_on 'libgcrypt'
  depends_on 'libjpeg'
  depends_on 'libpng'
  depends_on 'libsodium'
  depends_on 'libxpm'
  depends_on 'libzip'
  depends_on 'exif'
  depends_on 'freetds'
  depends_on 'freetype'
  depends_on 'graphite'
  depends_on 'oniguruma'
  depends_on 'pcre'
  depends_on 'py3_pygments'
  depends_on 're2c'

  depends_on 'libcurl' => :build
  depends_on 'libxslt' => :build
  depends_on 'tidy' => :build
  depends_on 'unixodbc' => :build

  no_fhs

  def self.preflight
    php_exec = File.join(CREW_PREFIX, 'bin', 'php')

    if File.exist?(php_exec)
      full_ver                = `#{php_exec} -v`[/^PHP ([^\s]+)/, 1]
      major_ver, minor_ver, _ = full_ver.split('.', 3)

      abort <<~EOT.yellow unless name == "php#{major_ver}#{minor_ver}"

        PHP version #{full_ver} installed.

        Run "crew remove php#{major_ver.eql?('5') ? '5' : "#{major_ver}#{minor_ver}"}; crew install #{name}" to install this version of PHP
      EOT
    end
  end

  def self.patch
    # Configuration
    File.open('sapi/fpm/php-fpm.conf.in', 'r+') do |fileIO|
      fileIO.write fileIO.read \
        .sub(';pid = run/php-fpm.pid', "pid = #{CREW_PREFIX}/tmp/run/php-fpm.pid") \
        .sub(';error_log = log/php-fpm.log', "error_log = #{CREW_PREFIX}/log/php-fpm.log") \
        .sub('include=@php_fpm_sysconfdir@/php-fpm.d', "include=#{CREW_PREFIX}/etc/php-fpm.d") \
        .sub('^user', ';user') \
        .sub('^group', ';group') \
        .sub('@sbindir@', "#{CREW_PREFIX}/bin") \
        .sub('@sysconfdir@', "#{CREW_PREFIX}/etc") \
        .sub('@localstatedir@', "#{CREW_PREFIX}/tmp")
    end

    system 'sed', '-i', 's,^user,;user,', 'sapi/fpm/www.conf.in'
    system 'sed', '-i', 's,^group,;group,', 'sapi/fpm/www.conf.in'

    # Fix /usr/bin/file: No such file or directory
    system 'filefix'
  end

  def self.build
    system <<~BUILD
      ./configure #{CREW_OPTIONS} \
       --docdir=#{CREW_PREFIX}/doc \
       --infodir=#{CREW_PREFIX}/info \
       --localstatedir=#{CREW_PREFIX}/var \
       --sbindir=#{CREW_PREFIX}/bin \
       --with-config-file-path=#{CREW_PREFIX}/etc \
       --with-libdir=#{ARCH_LIB} \
       --with-kerberos=#{CREW_LIB_PREFIX} \
       --with-pear=#{CREW_LIB_PREFIX}/php \
       --with-zlib-dir=#{CREW_LIB_PREFIX} \
       --enable-bcmath \
       --enable-calendar \
       --enable-dba=shared \
       --enable-exif \
       --enable-fpm \
       --enable-ftp \
       --enable-gd \
       --enable-intl \
       --enable-mbstring \
       --enable-mysqlnd \
       --enable-opcache \
       --enable-pcntl \
       --enable-shared \
       --enable-shmop \
       --enable-soap \
       --enable-sockets \
       --enable-sysvmsg \
       --with-bz2 \
       --with-curl \
       --with-ffi \
       --with-freetype \
       --with-gdbm \
       --with-gettext \
       --with-gmp \
       --with-jpeg \
       --with-ldap \
       --with-ldap-sasl \
       --with-libedit \
       --with-mysqli \
       --with-openssl \
       --with-pdo-mysql \
       --with-pspell \
       --with-readline \
       --with-sodium \
       --with-tidy \
       --with-unixODBC \
       --with-xmlrpc \
       --with-xsl \
       --with-zip
    BUILD

    system 'make'
  end

  def self.check
    # system 'make', 'test'
  end

  def self.install
    FileUtils.mkdir_p %W[#{CREW_DEST_PREFIX}/log #{CREW_DEST_PREFIX}/tmp/run #{CREW_DEST_PREFIX}/etc/init.d #{CREW_DEST_PREFIX}/etc/php-fpm.d]

    system 'make', "INSTALL_ROOT=#{CREW_DEST_DIR}", 'install'

    FileUtils.install 'php.ini-development', "#{CREW_DEST_PREFIX}/etc/php.ini", mode: 0o644
    FileUtils.install 'sapi/fpm/init.d.php-fpm.in', "#{CREW_DEST_PREFIX}/etc/init.d/php-fpm", mode: 0o755
    FileUtils.install 'sapi/fpm/php-fpm.conf.in', "#{CREW_DEST_PREFIX}/etc/php-fpm.conf", mode: 0o644
    FileUtils.install 'sapi/fpm/www.conf.in', "#{CREW_DEST_PREFIX}/etc/php-fpm.d/www.conf", mode: 0o644

    FileUtils.ln_s "#{CREW_PREFIX}/etc/init.d/php-fpm", "#{CREW_DEST_PREFIX}/bin/php7-fpm"

    # clean up some files created under #{CREW_DEST_DIR}. check http://pear.php.net/bugs/bug.php?id=20383 for more details
    FileUtils.mv %W[#{CREW_DEST_DIR}/.depdb #{CREW_DEST_DIR}/.depdblock], "#{CREW_DEST_LIB_PREFIX}/php"
    FileUtils.rm_rf Dir["#{CREW_DEST_DIR}/.{channels,filemap,lock,registry}"]
  end

  def self.postinstall
    print "Start php-fpm on login? [Y/n]: "

    if %W[Y y \n].include?($stdin.getc)
      File.write "#{CREW_PREFIX}/etc/env.d/#{name}", <<~EOF
        # start php-fpm on login
        if [ -e #{CREW_PREFIX}/bin/php7-fpm ]; then
          #{CREW_PREFIX}/bin/php7-fpm start
        fi
      EOF
    end

    puts <<~EOT.lightblue

      To start the php-fpm service, execute:
      php7-fpm start

      To stop the php-fpm service, execute:
      php7-fpm stop

      To restart the php-fpm service, execute:
      php7-fpm restart

    EOT
  end

  def self.remove
    # remove env file if exist
    FileUtils.rm_f "#{CREW_PREFIX}/etc/env.d/#{name}"
  end
end
