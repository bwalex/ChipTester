require 'rubygems'
require 'yaml'

#Start up server initializations
start_up_config = YAML::parse(File.open( "config.yml" ))

if Admin.all(:email => start_up_config['admin']['username'].value).empty?
  @admin = Admin.create(
    :email => start_up_config['admin']['username'].value,
    :password => start_up_config['admin']['password'].value,
    :permission => start_up_config['admin']['permission'].value
    )
  @admin.save
end