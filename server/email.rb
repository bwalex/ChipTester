require 'net/smtp'

def send_email(to,opts={})
  opts[:server]      ||= '152.78.168.139'
  opts[:from]        ||= 'chiptester@chiptester.com'
  opts[:from_alias]  ||= 'Example Emailer'
  opts[:subject]     ||= "Chip Tester"
  opts[:body]        ||= "Important stuff!"

  msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE
  Net::SMTP.start('mail.google.com',25,'localhost','user','password') do |smtp|
    smtp.send_message msg,opts[:from], to
  end
end

