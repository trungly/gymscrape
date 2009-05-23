require 'rubygems'
require 'sinatra'
require 'sinapp'

root_dir = File.dirname(__FILE__)

set :root,        root_dir
set :app_file,    File.join(root_dir, 'sinapp.rb')
disable :run

run Sinatra::Application
