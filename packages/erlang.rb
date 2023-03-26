require 'package'

class Erlang < Package
  description 'Erlang is a programming language used to build massively scalable soft real-time systems with requirements on high availability.'
  homepage 'https://www.erlang.org/'
  version '25.3'
  license 'Apache-2.0'
  compatibility 'all'
  source_url 'https://github.com/erlang/otp/releases/download/OTP-25.3/otp_src_25.3.tar.gz'
  source_sha256 '85c447efc1746740df4089d75bc0e47b88d5161d7c44e9fc4c20fa33ea5d19d7'

  no_shrink

  depends_on 'openjdk8'
  depends_on 'wxwidgets'

  def self.build
    system "./configure #{CREW_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
