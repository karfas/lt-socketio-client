# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'extensions/client'

Gem::Specification.new do |s|
  s.name        = "lt-socketio-client"
  s.version     = LTSocketIO::Client::VERSION
  s.authors     = ["Nikita Skryabin"]
  s.email       = ["ns@level.travel"]
  s.homepage    = "http://github.com/nicholasrq/lt-socketio-client"
  s.summary     = %q{Ruby analog of Socket.IO JavaScript client}
  s.description = %q{Uses WebSocket universal Ruby gem to handle WS protocol}

  # s.rubyforge_project = "lt-socketio-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "websocket"
end
