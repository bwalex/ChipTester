require 'sinatra'
require 'json'

get '/hi' do
  "Hello world!"
end

get '/test' do
  "Message for you!"
end


delete '/test' do
end


post '/test' do
  content_type :json

  puts 'Content Type:   ' << request.content_type
  puts 'Content Length: ' << request.content_length
  puts 'Request body:   ' << request.body.read

  { :key1 => 'value1', :key2 => 'value2' }.to_json
end


put '/test' do
  content_type :json

  puts 'Content Type:   ' << request.content_type
  puts 'Content Length: ' << request.content_length
  puts 'Request body: ' << request.body.read

  { :key3 => 'value3', :key4 => [1,2,3,4] }.to_json
end


patch '/test' do
  content_type :json

  puts 'Content Type:   ' << request.content_type
  puts 'Content Length: ' << request.content_length
  puts 'Request body: ' << request.body.read

  { :key3 => 'value3', :key4 => { :subkey1 => [1,2], :subkey2 => 'hi', :subkey3 => nil} }.to_json
end
