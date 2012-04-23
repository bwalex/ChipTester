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

get '/failed_tests' do
  @fails = Fail.all
    erb :failed_tests
end

get '/failed_tests/:result_id' do
    @fails = Fail.all(:result_id => params[:result_id])
    erb :failed_tests
end

post '/' do
   unless params['json_posted'].nil?
      test = {}
      previous_result = nil
      json_parsed = JSON.parse(params['json_posted'])
      if json_parsed.has_key? "Result"
	    previous_result = Store_DUV_Result(json_parsed)
	    test = { "id" => previous_result.id }
      end
      if json_parsed.has_key? "Fail"
	    id = Store_DUV_Fail(json_parsed).id
	    test = { "id" => id }
      end
   end
      #rhtml.result(results.get_binding)
      test.to_json()
end

post '/reset' do
    #Destroying all the records
     Fail.all.destroy
     Result.all.destroy
     return '<p>The database has been cleaned</p>'
end
