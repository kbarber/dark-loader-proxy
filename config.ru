$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'sinatra'

set :environment, ENV['RACK_ENV'].to_sym
disable :run, :reload

require 'server.rb'

run App
