require 'sinatra'

set :env,  :production
disable :run

require './server.rb'

run Sinatra::Application
