require 'bcrypt'

include BCrypt

if ARGV.length == 1
  puts "The encrypted password is:\n" + BCrypt::Password.create(ARGV[0])
else
  usage
end

def usage
  puts "ruby -rubygems pass.rb password\n"
end
