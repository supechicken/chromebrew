require 'package'

class Elixir < Package
  description 'Elixir is a dynamic, functional language designed for building scalable and maintainable applications.'
  homepage 'https://elixir-lang.org/'
  version '1.14.3'
  license 'Apache-2.0 and ErlPL-1.1'
  compatibility 'all'
  source_url 'https://github.com/elixir-lang/elixir/archive/refs/tags/v1.14.3.tar.gz'
  source_sha256 'bd464145257f36bd64f7ba8bed93b6499c50571b415c491b20267d27d7035707'

  depends_on 'erlang'

  def self.build
    system 'make'
  end

  def self.test
    system 'make', 'test'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
