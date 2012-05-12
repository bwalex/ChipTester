require 'rubygems'
require 'yaml'

#Start up server initializations
start_up_config = YAML::load(File.open( "config.yml" ))

if Admin.all(:email => start_up_config['admin']['username']).empty?
  @admin = Admin.create(
    :email => start_up_config['admin']['username'],
    :password => start_up_config['admin']['password'],
    :permission => start_up_config['admin']['permission']
    )
  @admin.save
end
