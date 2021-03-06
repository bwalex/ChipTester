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

config = YAML::load( File.open( "config.yml" ))
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
   if Admin.first(:email => session['user']).nil?
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
   @results = Result.all(:order => [ :created_at.desc ])
   erb :overview
end

#Design Result view
get '/DesignResult/:result_id' do
    @designs = DesignResult.all(:result_id => params[:result_id])
    erb :design_result
end

#Design Result Test View
get '/DesignResult/TestResult/:design_result_id' do
    @design = DesignResult.get(params[:design_result_id])
    @tests = TestVectorResult.all(:design_result_id => params[:design_result_id])
    erb :test_result
end

get '/DesignResult/frequency/:design_result_id' do
    @design = DesignResult.get(params[:design_result_id])
    @freqs = FrequencyMeasurement.all(:design_result_id => params[:design_result_id])
    erb :freq_meas
end

get '/DesignResult/adc/:design_result_id' do
    @design = DesignResult.get(params[:design_result_id])
    @adcs = AdcMeasurement.all(:design_result_id => params[:design_result_id])
    erb :adc_capture
end


get '/adc/:adc_id/figure' do
  @adc = AdcMeasurement.get(params[:adc_id])
  send_file @adc.png_path,
    :type => 'image/png',
    :disposition => 'inline'
end

get '/adc/:adc_id/raw' do
  @adc = AdcMeasurement.get(params[:adc_id])
  send_file @adc.path,
    :type => 'application/octet-stream',
    :disposition => 'attachment'
end

get '/adc/:adc_id/csv' do
  @adc = AdcMeasurement.get(params[:adc_id])
  content_type "text/csv"
  @adc.as_csv
end


#Login View
get '/admin_login' do
  @flash_error = flash
    if Admin.first(:email => session['user']).nil?
      erb :login
    else
      redirect '/admin'
    end
end

#Log Entries view
get '/LogEntries' do
  @logs = LogEntry.all(:order => [ :created_at.desc ])
  erb :log_entry
end

get '/add_admin' do
  @flash_error = flash
  if Admin.first(:email => session['user']).permission == 0
    erb :add_admin
  elsif Admin.first(:email => session['user']).nil?
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
  if Admin.create_admin(params['email'], params['permission'], params['password'])
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
      StoreFileUpload(params['email'], params['team_number'], md5_name, true)
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


post '/api/result' do
  content_type :json
  @result = Result.new
  JSON.parse(request.body.read).each { |k, v| @result.send(k + "=", v) }
  @result.save

  @result.to_json
end


post '/api/result/:result_id/design' do
  content_type :json
  data =  JSON.parse(request.body.read)
  @result = Result.get!(params[:result_id])
  @design = @result.design_results.create(data)
  @result.save

  @design.to_json

end

post '/api/result/:result_id/design/:design_id/measurement/frequency' do
  content_type :json
  data =  JSON.parse(request.body.read)
  @result = Result.get!(params[:result_id])
  @design = DesignResult.get!(params[:design_id])
  @fm = @design.frequency_measurements.create(data)

  @fm.to_json
end

post '/api/result/:result_id/design/:design_id/measurement/adc' do
  content_type :json
  @result = Result.get!(params[:result_id])
  @design = DesignResult.get!(params[:design_id])
  @ad = @design.adc_measurements.create
  @ad.data = request.body.read
  @ad.to_json
end


post '/api/result/:result_id/design/:design_id/vector' do
  content_type :json
  data =  JSON.parse(request.body.read)
  @result = Result.get!(params[:result_id])
  @design = DesignResult.get!(params[:design_id])
  @vector = @design.test_vector_results.create(data)

  @vector.to_json
end


post '/api/log' do
  content_type :json
  data = JSON.parse(request.body.read)
  @log = LogEntry.create(data)

  @log.to_json
end


post '/api/done/:result_id' do
  @result = Result.get(params[:result_id])
  if !@result.nil?
    if @result.mail_sent or @result.email == "" or config['email']['email_enable']
	@result.update(:mail_sent => send_mail(@result))
    end
  else
    'No result associated to the team'
  end
end


get '/api/vdesign' do
  @fu = FileUpload.first
  if @fu.nil?
    halt 404
  else
    file = File.join('uploads/', @fu.file_name)
    @fu.destroy
    send_file(file, :disposition => 'attachment', :filename => File.basename(file))
    #Nothing after the send_file is executed
  end
end

delete '/api/received/:name' do
  file = File.join('uploads/', params[:name])
  File.delete(file)
end
post '/logout_submited' do
    session[:user] = nil
    redirect '/'
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
    begin
         if Admin.authenticate(params['username'],params['password'])
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
	    results_designs.frequency_measurements.destroy
	    results_designs.adc_measurements.destroy
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
      DesignResult.get(erase_id).frequency_measurements.destroy
      DesignResult.get(erase_id).adc_measurements.destroy
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
    
def send_mail(result) 
  config = YAML::load( File.open( "config.yml" ))
  @results = result
  @designs = result.design_results
  @web_address = config['web']['server_address']
  str = erb :email_body, :layout => false
  return send_email_api(@result.email, str, 'Results')
end
