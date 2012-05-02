require 'rubygems'
require 'sinatra' 
require './database.rb'
require 'erb'
require 'json'
require './email.rb'
require './init.rb'
require 'sinatra/flash'
require 'sass'

#Enabling Sessions
enable :sessions

get '/css/style.css' do
   scss :style, :style => :expanded
end

get '/' do
   @results = Result.all
   erb :overview
end

get '/upload_files' do
  @flash_error = flash
  erb :upload_files
end

post '/submited_files' do
  errors = false
  error_msg = ''
  if params['uploaded_file'].nil?
    error_msg = error_msg + "A file must be specified. \n"
    errors = true
  end
  if params['email'].empty?
    error_msg = error_msg + "An email must be specified. \n"
    errors = true
  end
   if params['team_number'].empty?
    error_msg = error_msg + "A team number must be specified. \n"
    errors = true
  end
  if errors
    flash[:error] = error_msg
    redirect "/upload_files"
  else
      upload_files = {'file_name'=> params['uploaded_file'][:filename], 'email' => params['email'], 'team' => params['team_number'], 'file_hash' => 'x', 'sent' => false, 'erased' => 'false'}
      StoreFileUpload(upload_files)
      File.open('uploads/' + params['uploaded_file'][:filename], "w") do |f|
      f.write(params['uploaded_file'][:tempfile].read)
  end
  "The file was successfully uploaded!"
  end
end
get '/admin' do
   erb :admin
end

get '/DesignResult/:result_id' do
    @designs = DesignResult.all(:result_id => params[:result_id])
    erb :design_result
end

get '/DesignResult/TestResult/:design_result_id' do
    @tests = TestVectorResult.all(:design_result_id => params[:design_result_id])
    erb :test_result
end

get '/LogEntries' do
  @logs = LogEntry.all
  erb :log_entry
end

post '/' do
   unless params['json_posted'].nil?
      id_value = {}
      json_parsed = JSON.parse(params['json_posted'])
      
      if json_parsed.has_key? "LogEntry"
	  log_stored = Store_LogEntry(json_parsed)
	  id_value = {"id" => log_stored.id}
      end
      if json_parsed.has_key? "Result"
	    result_stored = StoreResult(json_parsed)
	    id_value = { "id" => result_stored.id }
      end
      if json_parsed.has_key? "DesignResult"
	    design_stored = StoreDesignResult(json_parsed)
	    id_value = { "id" => design_stored.id }
      end
      if json_parsed.has_key? "TestVectorResult"
	    test_stored = StoreTestVectorResult(json_parsed)
	    id_value = { "id" => test_stored.id }
      end
   end
      id_value.to_json()
end

post '/reset' do
    #Destroying all the records
     TestVectorResult.all.destroy
     DesignResult.all.destroy
     Result.all.destroy
     return '<p>The database has been cleaned</p>'
end


