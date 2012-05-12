require 'data_mapper'
require 'yaml'

database_config = YAML::parse( File.open( "config.yml" ))
config = database_config['database']['type'].value + '://' + database_config['database']['user'].value + ':' + database_config['database']['password'].value + '@' + database_config['database']['address'].value +  '/' + database_config['database']['database_name'].value
DataMapper.setup(:default, config)
#Refer to config.yml to change the config line
DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true
class Admin
 include DataMapper::Resource
 property :email, String, :key => true #Natural primary key
 property :password, String, :required =>true
 property :permission, Integer, :required =>true
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
  property :type, Integer # 0 -> info, 1 -> warn, 2 -> error
  property :message, String
  property :file, String
  property :line, Integer
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Result
  include DataMapper::Resource
  property :id, Serial
  property :team, Integer # 1
  property :academic_year, String # 2011/12
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
end

class FrequencyMeasurement
  include DataMapper::Resource
  property :id, Serial
  belongs_to :design_result
  property :frequency, Float
  property :created_at, DateTime
  property :updated_at, DateTime
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
DataMapper.finalize
