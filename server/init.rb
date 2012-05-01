require 'rubygems'
require 'yaml'

#Start up server initializations
start_up_config = YAML::parse(File.open( "config.yml" ))

if Admin.all(:email => start_up_config.select("MASTER.ADMIN")[0].value).empty?
  @admin = Admin.create(
    :email => start_up_config.select("MASTER.ADMIN")[0].value,
    :password => start_up_config.select("MASTER.PASSWORD")[0].value,
    :permission => start_up_config.select("MASTER.PERMISSION")[0].value
    )
  @admin.save
end