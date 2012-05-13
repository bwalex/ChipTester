require 'rubygems'
require 'sinatra' 
require './database.rb'
require 'erb'
require 'json'
require './email.rb'
require './init.rb'
require 'sinatra/flash'
require 'sass'
require 'digest/md5'
require 'mail'

config = YAML::parse( File.open( "config.yml" ))
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
   if Admin.all(:email => session['user'])[0].nil?
     redirect '/admin_login' 
   else
     @username = session['user']
     erb :admin
   end
end

get '/admin_database' do
  @FilesUploaded = FileUpload.all
  @flash_error = flash
  @tests = TestVectorResult.all
  @designs = DesignResult.all
  @results = Result.all
  erb :admin_database
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
#Login View
get '/admin_login' do
  @flash_error = flash
    if Admin.all(:email => session['user'])[0].nil?
      erb :login
    else
      redirect '/admin'
    end
end

#Log Entries view
get '/LogEntries' do
  @logs = LogEntry.all
  erb :log_entry
end

get '/download_configuration' do 
  @files_uploaded = (FileUpload.all(:erased => false) & FileUpload.all(:sent => false) & FileUpload.all(:is_valid => true)).all(:order => [ :uploaded_at.desc ])
  @files_resend = (FileUpload.all(:erased => false) & FileUpload.all(:sent => true) & FileUpload.all(:is_valid => true)).all(:order => [ :uploaded_at.desc ])
  file = nil
  if !@files_uploaded.empty?
    @files_uploaded.each_index do |idx| file_uploaded = @files_uploaded[idx]
      if idx == 0 
	  file = File.join('uploads/', file_uploaded.file_name)
	  file_uploaded.update(:sent => true) #Update it before erasing it
      else
	  @files_uploaded.update(:is_valid => false) #Update it before erasing it
      end
    end
  elsif !@files_resend.empty?
    #We have sent this already but if it didn't work I will keep sending it until we get any confirmation
    @files_resend.each_index do |idx| file_resend = @files_resend[idx]
	if idx == 0
	  file = File.join('uploads/', file_resend.file_name)
	else
	  file_resend.update(:is_valid => false)
	  #It is no longer valid
	end
      end
   end
  if file == nil
   status 404
  else
    send_file(file, :disposition => 'attachment', :filename => File.basename(file))
  end 
end

get '/add_admin' do
  @flash_error = flash
  if Admin.all(:email => session['user'])[0].permission == 0
    erb :add_admin
  elsif Admin.all(:email => session['user'])[0].nil?
    erb :login
  else
    flash[:error] = "You do not have the valid permissions to add new administrators. <br />"
    redirect '/admin'
  end
end

post '/added_admin' do
  errors = false
  error_msg = ''
  if params['email'].empty?
    error_msg = error_msg + "A valid <i>E-Mail</i> must be specified. <br />"
    errors = true
  elsif params['email'] !~ /^.+@.+\..+$/
    error_msg = error_msg + "A valid <i>E-Mail</i> must be specified. You entered <i>" + params['email'] + "</i>. <br />"
    errors = true
  end
  if params['permission'].empty?
    error_msg = error_msg + "A valid permission must be submited. Permission 0 allows the new admin to add more admins, Permission 1 does not><br />"
    errors = true
  elsif params['permission'] =~ /^.+@.+\..+$/
    error_msg = error_msg + "A valid <i>Permission</i> must be specified. You entered <i>" + params['permission'] + "</i>. <br />"
    errors = true
  end
  if params['password'].empty?
    error_msg = error_msg + "Password cannot be empty<br />"
    errors = true
  end
  if params['password_rep'].empty?
    error_msg = error_msg + "Please Repeat the new admin password<br />"
    errors = true
  end
  if !params['password'].empty? && params['password'] != params['password_rep']
    error_msg = error_msg + "Passwords do not match<br />"
    errors = true
  end
  if errors
    flash[:error] = error_msg
    redirect '/add_admin'
  else
  if Admin.create(:email => params['email'], :password => params['password'], :permission => params['permission'])
    flash[:notice] = "New administrator created successfully<br />"
    redirect '/add_admin'
  else
    flash[:error] = "New admin could not be created<br />"
    redirect '/add_admin'
  end
  end
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
  else if params['team_number'] =~ /^.+@.+\..+$/
    error_msg = error_msg + "A valid <i>Team Number</i> must be specified. You entered <i>" + params['team_number'] + "</i>. <br />"
    errors = true
    end
  end
  
  unless params['uploaded_file'] &&
         (tempfile = params['uploaded_file'][:tempfile]) &&
         (name = params['uploaded_file'][:filename])
      error_msg = error_msg + "No file selected  <br />"
      errors = true
  end
  if errors
    flash[:error] = error_msg
    redirect "/upload_files"
  else
    #It does not allow repeated files
     md5_name = Digest::MD5.hexdigest(params['uploaded_file'][:tempfile].read) + File.extname(params['uploaded_file'][:filename])
     if FileUpload.all(:file_name => md5_name).empty?
      StoreFileUpload(params['email'], params['team_number'], md5_name, true, false, false)
      directory = "public/files"
      filename = File.join('uploads/', name)
      FileUtils.cp tempfile.path, 'uploads/' + md5_name
      flash[:notice] = "The file was successfully uploaded! <br />"
      redirect "/upload_files"
     else
       flash[:error] = "This file has been already uploaded <br />"
       redirect "/upload_files"
     end
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
      if json_parsed.has_key? "DownloadSuccess"
	@file_upload = FileUpload.all(:file_name=> json_parsed['DownloadSuccess']['file_name'])
	@file_upload.update(:sent=> true, :erased => true)
	File.delete('uploads/' + json_parsed['DownloadSuccess']['file_name'])
      end
   end
      id_value.to_json()
end

post '/logout_submited' do
    session[:user] = nil
    redirect '/'
end
post '/send_email_results' do
    unless params['json_posted'].nil?
	send_email_to_team(json_posted['send_email']['team_id'])
    end
    redirect '/admin'
end

post '/login_submitted' do
    errors = false
    erros_msg = ''
    if params['username'].nil? 
      error_msg = error_msg + "A <i>Username</i> must be specified. <br />"
      erros = true
    end
    if params['password'].nil?
      error_msg = error_msg  + "A <i>Password</i> must be specified. <br />"
      errors = true
    end
    if errors
       flash[:error] = error_msg
       redirect "/admin_login"
    end
    #ADD PASSWORD ENCRYPTION HERE
    begin
         if Admin.all(:email => params['username'])[0].password == params['password']
	   session['user'] = params['username']
	   redirect "/admin"
	 else
	   error_msg = error_msg + "Invalid <i>Username</i> or <i>Password</i><br />"
	   errors = true
	 end
    rescue 
	  flash[:error] = "Invalid <i>Username</i> or <i>Password</i><br />"
	  redirect "/admin_login"
    end
end

post '/reset' do
    #Destroying all the records
     LogEntry.all.destroy
     FileUpload.all.destroy
     TestVectorResult.all.destroy
     DesignResult.all.destroy
     Result.all.destroy
     flash[:notice] = "The database has been cleaned <br />"
     redirect '/admin_database'
end

post '/manage_results' do
  str = ''
  puts params['erase_result']
	begin
	  params['erase_result'].each {|erase_id|
	  #Erasing first the results design asociated to this result
	    results_designs = Result.get(erase_id).design_results
	    results_designs.each {|results_design|
	    results_designs.test_vector_results.destroy
	  }        
	  Result.get(erase_id).design_results.destroy
	  Result.get(erase_id).destroy     
	}
	flash[:notice] = "The data has been erased successfully!"
      rescue
	flash[:error] = "Error: The data could not be erased."
      end
    redirect "/admin_database"
end

post '/manage_designs' do
      begin
      params['erase_design'].each {|erase_id|
      #@ Results.all(:id => erase_id).
      DesignResult.get(erase_id).test_vector_results.destroy
      DesignResult.get(erase_id).destroy                            
    }
	flash[:notice] = "The data has been erased successfully!"
      rescue 
	flash[:error] = "Error: The data could not be erased."
      end
    redirect "/admin_database"
end

post '/manage_test_result' do
      
     begin
	  params['erase_test_result'].each {|erase_id|
	  puts erase_id
	  TestVectorResult.get(erase_id).destroy
	  }
	flash[:notice] = "The data has been erased successfully"
      rescue
	flash[:error] = "The data could not be erased"
      end
    redirect "/admin_database"
end

post '/manage_file_upload' do
  begin
    	  params['erase_file_upload'].each {|erase_id|
	  FileUpload.get(erase_id).destroy
	  }
	flash[:notice] = "The data has been erased successfully"
      rescue
	flash[:error] = "The data could not be erased"
      end
    redirect "/admin_database"
end
    
def send_email_to_team(team_id)  
  @results = Result.all(:team => team_id)
  @designs = @results.design_results
  str = erb :email_body
  if email = FileUpload.all(:team => team_id)[0].email
    send_email(email, str, 'Results')
  end
end
