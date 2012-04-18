require 'rubygems'
require 'sinatra' 
require './database.rb'
require 'erb'
require './erb_binding.rb'
require 'json'


get '/css/style.css' do
   scss :style, :style => :expanded
end

get '/' do
   @results = Result.all
   erb :overview
end

get '/admin' do
   erb :admin
end

post '/' do
   unless params['json_posted'].nil?
      test = {}
      json_parsed = JSON.parse(params['json_posted'])
      if json_parsed.has_key? "Result"
	    id = Store_DUV_Result(json_parsed)
	    test = { "id" => id }
      end
      if json_parsed.has_key? "Fail"
	    Store_DUV_Fail(json_parsed)
      end
   end
      #rhtml.result(results.get_binding)
      "Something Has Happened REMEMBER TO DO THE JSON RETURN"
      test.to_json()
end

post '/reset' do
    #Destroying all the records
     Result.all.destroy
     return '<p>The database has been cleaned</p>'
end
