require 'rubygems'
require 'mail'
require 'yaml'

email_config = YAML::parse( File.open( "config.yml" ) )
Mail.defaults do
  delivery_method :smtp, {:address => email_config['email']['smtpaddress'].value,
			  :port => email_config['email']['port'].value,
			  :user_name =>email_config['email']['username'].value,
			  :domain => email_config['email']['domain'].value,
			  :password => email_config['email']['password'].value,
			  :authentication => email_config['email']['authentication'].value,
			  :enable_starttls_auto => email_config['email']['enable_ttls'].value

}
end

def send_email(to_address, e_body, e_subject)
  email_config = YAML::parse( File.open( "config.yml" ) )
  if email_config['email']['email_enable'].value
	mail = Mail.new do
	from email_config['email']['username'].value
	content_type 'text/html; charset=UTF-8'
	to to_address
	subject e_subject
	body e_body
	
	end
  mail.deliver!
  return 'sent'
  else
    return 'Email not enabled'
  end
end
