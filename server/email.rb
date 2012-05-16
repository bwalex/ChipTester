require 'rubygems'
require 'mail'
require 'yaml'

email_config = YAML::load( File.open( "config.yml" ) )
Mail.defaults do
  delivery_method :smtp, {:address => email_config['email']['smtpaddress'],
			  :port => email_config['email']['port'],
			  :user_name =>email_config['email']['username'],
			  :domain => email_config['email']['domain'],
			  :password => email_config['email']['password'],
			  :authentication => email_config['email']['authentication'],
			  :enable_starttls_auto => email_config['email']['enable_ttls']

}
end

def send_email(to_address, e_body, e_subject)
  
  mail = Mail.new do
  from email_config['email']['username']
  content_type 'text/html; charset=UTF-8'
  to to_address
  subject e_subject
  body e_body
  end
  begin
    mail.deliver!
    return true
  rescue
    return false
  end
end
