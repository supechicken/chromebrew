require 'digest/sha2'
require 'uri'

$LOAD_PATH << File.expand_path('../../lib')
require_relative '../../lib/color'
require_relative '../../lib/package'

CHANGED_FILES = `git diff --name-only #{ENV['DEFAULT_BRANCH']}...HEAD`.chomp.lines

def validate_sha256sum (fileIO, sha256sum)
  puts "[#{pkg.name}]: Validating checksum... (SHA256: #{sha256sum})"
  actual_sha256sum = Digest::SHA256.hexdigest(fileIO.read)
  abort "[#{pkg.name}]: Checksum mismatch!".lightred unless actual_sha256sum == sha256sum
end

def test_url (arch, url)
  abort "[#{pkg.name}]: Link to #{arch} prebuilt binary is a local file!".lightred if URI(url).scheme == 'file'

  puts "[#{pkg.name}]: Testing connectivity of #{arch} prebuilt binary URL..."
  status_code = `curl -IL #{url.inspect}`.scan(/^HTTP[^ ]* (\d+)/)[-1][0]
  abort "Server returned a bad HTTP status code!".lightred if status_code[0] == '4'
end

def check_binary_url
  CHANGED_FILES.each do |f|
    pkg = Package.load_package(f)

    unless pkg.binary_url.to_h.empty?
      warn "Skipping #{pkg.name}... (no prebuilt binary available)".yellow
      next
    end

    pkg.binary_url.keys.each do |arch|
      puts "[#{pkg.name}]: Checking prebuilt binary for #{arch}..."

      url = pkg.binary_url[arch]
      sha256sum = pkg.binary_sha256[arch]

      puts "[#{pkg.name}]: #{arch} prebuilt binary URL: #{url}".lightblue

      test_url(arch, url)

      puts "[#{pkg.name}]: Downloading prebuilt binary for #{arch}..."
      binary_fileIO = IO.popen(['curl', '-L', url])
      Process.wait(binary_fileIO.pid)

      puts "[#{pkg.name}]: Validating checksum... (SHA256: #{sha256sum})"
      actual_sha256sum = Digest::SHA256.hexdigest(binary_fileIO.read)
      abort "[#{pkg.name}]: Checksum mismatch!".lightred unless actual_sha256sum == sha256sum
    end
  end
end

def check_source_url
  CHANGED_FILES.each do |f|
    pkg = Package.load_package(f)

    if pkg.source_url.casecmp?('SKIP')
      warn "Skipping #{pkg.name}... (no source available)".yellow
      next
    end

    unless pkg.git_hashtag.nil? and pkg.git_branch.nil?
      warn "Skipping #{pkg.name}... (git URL)"
      next
    end

    if pkg.source_url.is_a?(Hash)
      # if source_url is a hash containing different source url for architectures
      pkg.source_url.keys.each do |arch|
        puts "[#{pkg.name}]: Checking source for #{arch}..."

        url = pkg.source_url[arch]
        sha256sum = pkg.source_sha256[arch]

        puts "[#{pkg.name}]: #{arch} source URL: #{url}".lightblue

        test_url(arch, url)

        puts "[#{pkg.name}]: Downloading source for #{arch}..."
        binary_fileIO = IO.popen(['curl', '-L', url])
        Process.wait(binary_fileIO.pid)

        validate_sha256sum(binary_fileIO, binary_sha256)
      end
    else
      # source_url with one url only
      puts "[#{pkg.name}]: Checking source URL..."

      url = pkg.source_url
      sha256sum = pkg.source_sha256

      puts "[#{pkg.name}]: #{arch} source URL: #{url}".lightblue

      test_url(arch, url)

      puts "[#{pkg.name}]: Downloading source..."
      binary_fileIO = IO.popen(['curl', '-L', url])
      Process.wait(binary_fileIO.pid)

      validate_sha256sum(binary_fileIO, binary_sha256)
    end
  end
end

send(ARGV[0].to_sym)