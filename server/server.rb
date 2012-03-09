require 'rubygems'
require 'sinatra'
require 'data_mapper' 
require 'database.rb'
require 'erb'
require 'erb_binding.rb'
require 'json'

#Open the view file
f = File.open("views/TableTemplate.txt")
  rhtml = ERB.new(f.read)
f.close

#Map from the database the test result.
results = Results_Bind.new('',DUV_Results.all,'')

get '/' do
    rhtml.result(results.get_binding)
end 

post '/' do
   unless params['json_posted'].nil?
      json_parsed = JSON.parse(params['json_posted'])
      if json_parsed.has_key? "DUV_Results"
	    Store_DUV_Result(json_parsed)
      end
      if json_parsed.has_key? "DUV_Fail"
	    Store_DUV_Fail(json_parsed)
      end
   end
      rhtml.result(results.get_binding)
end

post '/reset' do
    #Destroying all the records
     DUV_Results.all.destroy
     return '<p>The database has been cleaned</p>'
end