require 'package'

class Fop < Package
  description 'Apache FOP (Formatting Objects Processor) is a print formatter driven by XSL formatting objects (XSL-FO) and an output independent formatter.'
  homepage 'https://xmlgraphics.apache.org/fop/'
  version '2.7'
  license 'Apache-2.0'
  compatibility 'all'

  source_url 'https://downloads.apache.org/xmlgraphics/fop/binaries/fop-2.7-bin.tar.gz'
  source_sha256 'ec75d6135f55f57b275f8332e069f8817990fdc7f63b1f5c0cb9da5609aa3074'

  no_compile_needed

  depends_on 'openjdk8'

  def self.install
    FileUtils.mkdir_p %w[#{CREW_DEST_PREFIX}/bin #{CREW_DEST_LIB_PREFIX}/fop]
    FileUtils.cp_r Dir['*'], "#{CREW_DEST_LIB_PREFIX}/fop/"

    File.write "#{CREW_DEST_PREFIX}/bin/fop", <<~EOF
      #!/bin/bash -e

      cd #{CREW_LIB_PREFIX}/fop/fop
      exec ./fop "${@}"
    EOF
  end
end
