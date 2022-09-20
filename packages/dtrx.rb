require 'package'

class Dtrx < Package
  description "An intelligent archive extraction tool for UNIX-like systems standing for 'Do The Right Extraction.'"
  homepage 'https://github.com/dtrx-py/dtrx'
  version '8.4.0'
  license 'GPL-3'
  compatibility 'all'
  source_url 'https://github.com/dtrx-py/dtrx/releases/download/8.4.0/dtrx-8.4.0.tar.gz'
  source_sha256 'e96b87194481a54807763b33fc764d4de5fe0e4df6ee51147f72c0ccb3bed6fa'

  no_compile_needed

  depends_on 'binutils'
  depends_on 'bz2'
  depends_on 'cabextract'
  depends_on 'cpio'
  depends_on 'lha'
  depends_on 'python3'
  depends_on 'unrar'
  depends_on 'unshield'
  depends_on 'unzip'

  def self.install
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    system "python3 setup.py install #{PY_SETUP_INSTALL_OPTIONS}"
    FileUtils.install "#{CREW_PREFIX}/bin/dtrx", "#{CREW_DEST_PREFIX}/bin", mode: 0o755
  end
end
