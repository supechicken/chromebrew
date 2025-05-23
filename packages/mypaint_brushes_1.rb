require 'package'

class Mypaint_brushes_1 < Package
  description 'Brushes used by MyPaint and other software using libmypaint.'
  homepage 'https://mypaint.app/'
  version '1.3.1'
  license 'CC0-1.0'
  compatibility 'aarch64 armv7l x86_64'
  source_url 'https://github.com/mypaint/mypaint-brushes.git'
  git_hashtag "v#{version}"
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: 'd4c52770e79f9752640e1925d3da1bf273f86702a3dba5286ebdb8d9265363a1',
     armv7l: 'd4c52770e79f9752640e1925d3da1bf273f86702a3dba5286ebdb8d9265363a1',
     x86_64: '2788325174fd8ba648a99146ad7feb6960eea153998ff175378cb758853f9056'
  })

  depends_on 'libmypaint'

  def self.build
    system 'env NOCONFIGURE=1 ./autogen.sh'
    system "./configure #{CREW_CONFIGURE_OPTIONS}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
  end
end
