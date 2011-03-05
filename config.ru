require 'rubygems'
require 'bundler/setup'

require 'lib/favlis'

use Rack::ShowExceptions
run Rack::URLMap.new("/" => Favlis::App.new)

