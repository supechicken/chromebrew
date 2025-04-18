require 'package'

class Ca_certificates < Package
  description 'Common CA Certificates PEM files'
  homepage 'https://salsa.debian.org/debian/ca-certificates'
  @mozilla_git_tag = '5b78b93999ad54e54b18054c21697f8e857e57a6'
  version '20241223-5b78b93' # Do not replace version with @_ver, the install will break.
  license 'MPL-1.1'
  compatibility 'all'
  source_url 'https://salsa.debian.org/debian/ca-certificates.git'
  git_hashtag '9ad250adb22da86f2f0929ecff081cf86919ac6e'
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '3afefe052aafab0eef1c3850d140dd71e42bc6d2b1dd838de33c97bb7fd2ff2c',
     armv7l: '3afefe052aafab0eef1c3850d140dd71e42bc6d2b1dd838de33c97bb7fd2ff2c',
       i686: '3abd902bb4fe85ddf0ecfd5371f6582a2a4f9f895cc2d36c02cf7683f0ced3a7',
     x86_64: '0008d1ff828dd9254e02e180340d87247b06a276b61da1f57736d33504eefc9a'
  })

  depends_on 'py3_cryptography' => :build

  print_source_bashrc

  def self.patch
    @mozilla_git_tag = 'a978bf84ac8e90eebe60778579565b977080368c'
    downloader "https://hg.mozilla.org/releases/mozilla-beta/raw-file/#{@mozilla_git_tag}/security/nss/lib/ckfw/builtins/certdata.txt", 'aaaa', 'mozilla/certdata.txt'
    downloader "https://hg.mozilla.org/releases/mozilla-beta/raw-file/#{@mozilla_git_tag}/security/nss/lib/ckfw/builtins/nssckbi.h", 'bbbb', 'mozilla/nssckbi.h'

    # Patch from:
    # https://gitweb.gentoo.org/repo/gentoo.git/plain/app-misc/ca-certificates/files/ca-certificates-20150426-root.patch
    @gentoo_patch = <<~GENTOO_CA_CERT_HEREDOC
               add a --root option so we can generate with DESTDIR installs
      #{'      '}
            --- a/image/usr/sbin/update-ca-certificates
            +++ b/image/usr/sbin/update-ca-certificates
            @@ -30,6 +30,8 @@ LOCALCERTSDIR=/usr/local/share/ca-certificates
             CERTBUNDLE=ca-certificates.crt
             ETCCERTSDIR=/etc/ssl/certs
             HOOKSDIR=/etc/ca-certificates/update.d
            +ROOT=""
            +RELPATH=""
      #{'       '}
             while [ $# -gt 0 ];
             do
            @@ -59,13 +61,25 @@ do
                 --hooksdir)
                   shift
                   HOOKSDIR="$1";;
            +    --root|-r)
            +      shift
            +      # Needed as c_rehash wants to read the files directly.
            +      # This gets us from $CERTSCONF to $CERTSDIR.
            +      RELPATH="../../.."
            +      ROOT=$(readlink -f "$1");;
                 --help|-h|*)
            -      echo "$0: [--verbose] [--fresh]"
            +      echo "$0: [--verbose] [--fresh] [--root <dir>]"
                   exit;;
               esac
               shift
             done
      #{'       '}
            +CERTSCONF="$ROOT$CERTSCONF"
            +CERTSDIR="$ROOT$CERTSDIR"
            +LOCALCERTSDIR="$ROOT$LOCALCERTSDIR"
            +ETCCERTSDIR="$ROOT$ETCCERTSDIR"
            +HOOKSDIR="$ROOT$HOOKSDIR"
            +
             if [ ! -s "$CERTSCONF" ]
             then
               fresh=1
            @@ -94,7 +107,7 @@ add() {
                                                               -e 's/,/_/g').pem"
               if ! test -e "$PEM" || [ "$(readlink "$PEM")" != "$CERT" ]
               then
            -    ln -sf "$CERT" "$PEM"
            +    ln -sf "${RELPATH}${CERT#{$ROOT}}" "$PEM"
                 echo "+$PEM" >> "$ADDED"
               fi
               # Add trailing newline to certificate, if it is missing (#635570)
    GENTOO_CA_CERT_HEREDOC
    File.write('ca-certificates-20150426-root.patch', @gentoo_patch)
    system 'patch -p 3 < ca-certificates-20150426-root.patch'

    system "sed -i 's,/usr/share/ca-certificates,#{CREW_PREFIX}/share/ca-certificates,g' \
      Makefile"
    system "sed -i 's,/usr/share/ca-certificates,#{CREW_PREFIX}/share/ca-certificates,g' \
      sbin/update-ca-certificates"
    system "sed -i 's,CERTSCONF=/etc/ca-certificates.conf,CERTSCONF=#{CREW_PREFIX}/etc/ca-certificates.conf,g' \
      sbin/update-ca-certificates"
    system "sed -i 's,ETCCERTSDIR=/etc/ssl/certs,ETCCERTSDIR=#{CREW_PREFIX}/etc/ssl/certs,g' \
      sbin/update-ca-certificates"
    system "sed -i 's,HOOKSDIR=/etc/ca-certificates/update.d,HOOKSDIR=#{CREW_PREFIX}/etc/ca-certificates/update.d,g' \
      sbin/update-ca-certificates"
    system "sed -i '/restorecon/d' sbin/update-ca-certificates"
    system "sed -i 's,/usr/sbin,#{CREW_PREFIX}/bin,g' sbin/Makefile"
  end

  def self.build
    system 'make'
  end

  def self.install
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/etc/ssl/certs/")
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/bin")
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/share/ca-certificates/")
    system "make DESTDIR=#{CREW_DEST_DIR} install"
    date_temp = `date -u`.chomp
    ca_cert_conf = <<~CA_CERT_CONF_HEREDOC
      # Automatically generated by Chromebrew package #{Module.nesting.first}
      # from ca-certificates-debian-#{version.split('-').first}
      # and from https://hg.mozilla.org/releases/mozilla-beta/rev/#{@mozilla_git_tag}
      # #{date_temp}
      # Do not edit.
    CA_CERT_CONF_HEREDOC
    File.write("#{CREW_DEST_PREFIX}/etc/ca-certificates.conf", ca_cert_conf)

    File.write '08-ca-certificates', <<~CA_CERT_ENVD_HEREDOC
      # Set the ssl certificates path for ruby.
      SSL_CERT_DIR="${CREW_PREFIX}/etc/ssl/certs"
      SSL_CERT_FILE="${CREW_PREFIX}/etc/ssl/certs/ca-certificates.crt"
    CA_CERT_ENVD_HEREDOC
    FileUtils.install '08-ca-certificates', "#{CREW_DEST_PREFIX}/etc/env.d/08-ca-certificates", mode: 0o644

    Dir.chdir "#{CREW_DEST_PREFIX}/share/ca-certificates" do
      system "find * -name '*.crt' | LC_ALL=C sort | sed '/examples/d' >> #{CREW_DEST_PREFIX}/etc/ca-certificates.conf"
    end
    system "sbin/update-ca-certificates --hooksdir '' --root #{CREW_DEST_DIR} --certsconf #{CREW_PREFIX}/etc/ca-certificates.conf"
    Dir.glob("#{CREW_DEST_PREFIX}/share/ca-certificates/mozilla/*.crt") do |cert_file|
      cert_basename = File.basename(cert_file, '.crt')
      FileUtils.ln_sf "#{CREW_PREFIX}/share/ca-certificates/mozilla/#{cert_basename}.crt",
                      "#{CREW_DEST_PREFIX}/etc/ssl/certs/#{cert_basename}.pem"
    end
  end

  # This isn't run from install.sh, but that's ok. This is for cleanup if updated after an install.
  def self.postinstall
    # Do not call system update-ca-certificates as that tries to update certs in /etc .
    if File.file?("#{CREW_PREFIX}/bin/update-ca-certificates")
      system "#{CREW_PREFIX}/bin/update-ca-certificates --fresh --certsconf #{CREW_PREFIX}/etc/ca-certificates.conf"
    else
      puts "#{CREW_PREFIX}/bin/update-ca-certificates is missing!".lightred
    end
  end
end
