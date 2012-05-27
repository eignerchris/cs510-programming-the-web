require 'rubygems'
require 'bundler'
Bundler.require

use Rack::CommonLogger

get '/' do
  erb :index
end

get '/about' do
  erb :about
end
