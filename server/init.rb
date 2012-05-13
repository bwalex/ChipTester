require 'rubygems'
require 'yaml'

#Start up server initializations
start_up_config = YAML::load(File.open( "config.yml" ))

if Admin.first(:email => start_up_config['admin']['username']).nil?
  Admin.create_first_admin(start_up_config['admin']['username'], start_up_config['admin']['permission'], start_up_config['admin']['password'])
end
