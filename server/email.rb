require 'rubygems'
require 'mail'
require 'yaml'

email_config = YAML::parse( File.open( "config.yml" ) )
Mail.defaults do
  delivery_method :smtp, {:address => email_config.select("RESULT.EMAIL.SEND.SMTPADDRESS")[0].value,
			  :port => email_config.select("RESULT.EMAIL.SEND.PORT")[0].value,
			  :user_name =>email_config.select("RESULT.EMAIL.SEND.USERNAME")[0].value,
			  :domain => email_config.select("RESULT.EMAIL.SEND.DOMAIN")[0].value,
			  :password => email_config.select("RESULT.EMAIL.SEND.PASSWORD")[0].value,
			  :authentication => email_config.select("RESULT.EMAIL.SEND.AUTHENTICATION")[0].value,
			  :enable_starttls_auto => email_config.select("RESULT.EMAIL.SEND.ENABLE.TTLS")[0].value
}
end

def send_email(to_address)
mail = Mail.new do
      from email_config.select("RESULT.EMAIL.SEND.USERNAME")[0].value
        to to_address
   subject 'Guess how am I sending this email?'
      body 'If you receive this email, our application soon should be senging emails then. We should ask Peter Wilson for an account to send mails Cheers Romel'
end

mail.deliver!
end