require 'buildsystems/ruby'

class Ruby_concurrent_ruby < RUBY
  description 'Modern concurrency tools for Ruby. Inspired by Erlang, Clojure, Scala, Haskell, F#, C#, Java, and classic concurrency patterns.'
  homepage 'https://github.com/ruby-concurrency/concurrent-ruby'
  version "1.3.5-#{CREW_RUBY_VER}"
  license 'MIT'
  compatibility 'all'
  source_url 'SKIP'

  conflicts_ok
  no_compile_needed
end
