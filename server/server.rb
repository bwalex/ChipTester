require 'rubygems'
require 'sinatra' 
require './database.rb'
require 'erb'
require 'json'
require './email.rb'
require './init.rb'
require 'sinatra/flash'
require 'sass'
require 'mail'

#Enabling Sessions
enable :sessions

get '/css/style.css' do
   scss :style, :style => :expanded
end



#Upload files view
get '/upload_files' do
  @flash_error = flash
  erb :upload_files
end

#Admin view
get '/admin' do
   erb :admin
end

#Overview 
get '/' do
   @results = Result.all
   erb :overview
end

#Design Result view
get '/DesignResult/:result_id' do
    @designs = DesignResult.all(:result_id => params[:result_id])
    erb :design_result
end

#Design Result Test View
get '/DesignResult/TestResult/:design_result_id' do
    @tests = TestVectorResult.all(:design_result_id => params[:design_result_id])
    erb :test_result
end

#Log Entries view
get '/LogEntries' do
  @logs = LogEntry.all
  erb :log_entry
end

post '/submited_files' do
  errors = false
  error_msg = ''
  if params['email'].empty?
    error_msg = error_msg + "A valid <i>E-Mail</i> must be specified. <br />"
    errors = true
  else if params['email'] !~ /^.+@.+\..+$/
    error_msg = error_msg + "A valid <i>E-Mail</i> must be specified. You entered <i>" + params['email'] + "</i>. <br />"
    errors = true
    end
  end
  if params['team_number'].empty?
    error_msg = error_msg + "A valid <i>Team Number</i> must be specified. <br />"
    errors = true
  else if params['team_number'] =~ /^+\D+$/
    error_msg = error_msg + "A valid <i>Team Number</i> must be specified. You entered <i>" + params['team_number'] + "</i>. <br />"
    errors = true
    end
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

get '/download_configuration' do 
  @files_uploaded = (FileUpload.all(:erased => false) & FileUpload.all(:sent => false)).all(:order => [ :uploaded_at.desc ])
  if !@files_uploaded.empty?
    file = File.join('uploads/', @files_uploaded[0].file_name)
    send_file(file, :disposition => 'attachment', :filename => File.basename(file))
  else
    "There is nothing to download. SENT JSON HERE"
  end
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


