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

def send_email(to_address)
mail = Mail.new do
      from email_config['email']['username'].value
        to to_address
   subject 'Guess how am I sending this email?'
      body 'If you receive this email, our application soon should be senging emails then. We should ask Peter Wilson for an account to send mails Cheers Romel'
end

mail.deliver!
end