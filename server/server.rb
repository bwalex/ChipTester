require 'rubygems'
require 'sinatra'
require 'data_mapper' 
require 'database.rb'
require 'erb'
require 'erb_binding.rb'
require 'json'

#Open the view file
f = File.open("views/TableTemplate.html")
  rhtml = ERB.new(f.read)
f.close

#Map from the database the test result.
results = Results_Bind.new('',Result.all,'')

get '/' do
   results = Results_Bind.new('',Result.all,'')
   return rhtml.result(results.get_binding)
end 

post '/' do
   unless params['json_posted'].nil?
      test = {}
      json_parsed = JSON.parse(params['json_posted'])
      if json_parsed.has_key? "Result"
	    id = Store_DUV_Result(json_parsed)
	    test = { "id" => id }
      end
      if json_parsed.has_key? "DUV_Fail"
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