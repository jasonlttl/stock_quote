require 'stock_quote'
require 'rubygems'
require 'bundler/setup'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr'
  c.hook_into :webmock
end

RSpec.configure do |config|
end
