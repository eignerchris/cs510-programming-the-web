require 'rubygems'
require 'bundler'
Bundler.require

require './app.rb'

map '/' do
  run App
end