require 'data_mapper'
require 'yaml'
require 'bcrypt'
require './plot.rb'


database_config = YAML::load( File.open( "config.yml" ))
config = database_config['database']['type'] + '://' + database_config['database']['user'] + ':' + database_config['database']['password'] + '@' + database_config['database']['address'] +  '/' + database_config['database']['database_name']
#DataMapper.setup(:default, config)
DataMapper.setup(:default, 'sqlite:test.db')
#Refer to config.yml to change the config line
DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true
  
class Admin
 include DataMapper::Resource
 include BCrypt
 property :email, String, :key => true #Natural primary key
 property :permission, Integer, :required =>true
 property :password_hash, BCryptHash, :required => true
 
 
def self.create_admin(email,permission,password)
   @admin = self.create(
     :email => email,
     :permission => permission,
     :password_hash => BCrypt::Password.create(password)
     )
   @admin.save
   return @admin 
end
 
def self.create_first_admin(the_email,the_permission,the_password)
   @admin = self.create(
     :email => the_email,
     :permission => the_permission,
     :password_hash => the_password
     )
   @admin.save
   return @admin 
end

def self.authenticate(username, password)
    u = Admin.first(:email => username)
    if u && u.password_hash == password
      true
    else
      nil
    end
  end
end

class FileUpload
  include DataMapper::Resource
  property :id, Serial
  property :email, String
  property :team,  Integer
  property :file_name, String 
  property :is_valid, Boolean

  # Useless properties
  property :sent, Boolean
  property :erased, Boolean
  property :uploaded_at, DateTime
  # End Useless properties

  property :created_at, DateTime
  property :updated_at, DateTime
end

class LogEntry
  include DataMapper::Resource
  property :id, Serial
  property :type, Integer
  property :message, String
  property :file, String
  property :line, Integer
  property :created_at, DateTime
  property :updated_at, DateTime

  def type_str
    case type
      when 1
        "Debug"
      when 2
        "Info"
      when 3
        "Warning"
      when 4
        "Error"
      else
        "Unknown (#{type})"
    end
  end
end

class Result
  include DataMapper::Resource
  property :id, Serial
  property :team, Integer # 1
  property :academic_year, String # 2011/12
  property :email, String
  property :created_at, DateTime
  property :updated_at, DateTime
  property :virtual, Boolean # whether it's a virtual design or not
  has n, :design_results
end

class DesignResult
  include DataMapper::Resource
  property :id, Serial
  belongs_to :result
  property :created_at, DateTime
  property :updated_at, DateTime
  property :triggers, String
  property :file_name, String # team3/design1/foo.vec
  property :clock_freq, String # 15 MHz
  property :design_name, String # 4-bit Adder
  has n, :test_vector_results
  has n, :frequency_measurements
  has n, :adc_measurements

  def pass_rate
    count = test_vector_results.count.to_f
    count_fail = test_vector_results.count(:fail => true).to_f
    return ((count-count_fail)/count).to_f unless count == 0
    return 0 if count == 0
  end

  def failed?
    (pass_rate != 1)
  end

  def triggers_formatted
    a = triggers.scan(/./).reverse
    str = ''
    a.each_index do |i|
      str << "Q#{i} & " if a[i] == '1'
    end

    str = str[0..-3] if str != ''
  end
end

class TestVectorResult
  include DataMapper::Resource
  property :id, Serial
  belongs_to :design_result
  property :type, Integer # e.g. 0 -> triggered, 1 -> fixed latency, ...
  property :input_vector, String # 1101000001
  property :expected_result, String # 1111010101
  property :actual_result, String # 10110101010
  property :cycle_count, Integer # how many cycles the execution took
  property :trigger_timeout, Boolean
  property :has_run, Boolean
  property :fail, Boolean
  property :created_at, DateTime
  property :updated_at, DateTime

  def type_str
    case type
      when 0
        "Fixed Latency"
      when 1
        "Triggered"
      else
        "Unknown"
    end
  end
end

class FrequencyMeasurement
  include DataMapper::Resource
  property :id, Serial
  belongs_to :design_result
  property :pin, String
  property :frequency, Float
  property :created_at, DateTime
  property :updated_at, DateTime

  def pin_pretty
    "Q#{pin}"
  end
end


class AdcMeasurement
  include DataMapper::Resource
  property :id, Serial
  belongs_to :design_result
  property :created_at, DateTime
  property :updated_at, DateTime

  def path
    "adc_data/#{id}.adc"
  end

  def png_path
    "adc_data/#{id}.png"
  end

  def as_csv
    y = []
    File.open(path, "rb:binary") do |f|
      bytes = f.read
      y = bytes.unpack("C*")
    end

    str = ''
    y.each do |v|
      str << "#{v}, "
    end

    str = str[0..-2] if str != ''
  end

  def data= d
    # Save data d to a file in public/adc
    Dir.mkdir("adc_data") unless File.exists?("adc_data")
    File.open(path, "w") do |f|
      # ... process the file
      f.syswrite(d)
    end
    # XXX: need gnuplot
    plot_png(path, png_path)
  end
end


def StoreFileUpload(email, team, file_name, valid_value, sent, erased)
  @uploaded_file = FileUpload.create(
  :email => email,
  :team => team,
  :file_name => file_name,
  :is_valid => valid_value,
  :sent => sent,
  :erased => erased,
  :uploaded_at => DateTime.now
)  
  @uploaded_file.save
end
 
def Change_password(the_pass)
   Admin.update(:password_hash => BCrypt::Password.create(the_pass))
end

DataMapper.finalize
