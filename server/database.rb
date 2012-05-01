require 'data_mapper'
require 'yaml'

database_config = YAML::parse( File.open( "config.yml" ))
DataMapper.setup(:default, database_config.select("SERVER.DATABASE.CONFIG")[0].value)
#Refer to config.yml to change the config line
DataMapper::Logger.new($stdout, :debug)

class Admin
 include DataMapper::Resource
 property :email, String, :key => true #Natural primary key
 property :password, String, :required =>true
 property :permission, Integer, :required =>true
end

class LogEntry
  include DataMapper::Resource
  property :id, Serial
  property :type, Integer # 0 -> info, 1 -> warn, 2 -> error
  property :message, String
  property :file, String
end

class Result
  include DataMapper::Resource
  property :id, Serial
  property :team, Integer # 1
  property :run_date, DateTime
  property :academic_year, Integer # 2011/12
  property :outcome, Integer # 0 -> pass, 1 -> fail
  property :created_at, DateTime
  property :updated_at, DateTime
  property :virtual, Boolean # whether it's a virtual design or not
  has n, :design_results
end

class DesignResult
  include DataMapper::Resource
  property :id, Serial
  belongs_to :result
  property :outcome, Integer # 0 -> pass, 1 -> fail
  property :run_date, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime
  property :file_name, String # team3/design1/foo.vec
  property :clock_freq, String # 15 MHz
  property :design_name, String # 4-bit Adder
  has n, :test_vector_results
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
  property :clock_freq, String # 15 MHz
  property :clock_connections, String # e.g. A1, A2, A23
  property :bitmask, String # Q1,Q2,Q4
  property :dontcare_mask, String # not implemented hardware-wise yet, but e.g. Q1, Q3, Q5
  property :trigger_mask, String # Q1 or Q2 or !Q5
  property :outcome, Integer # 0 -> pass, 1 -> fail
  property :trigger_timeout, Boolean
  property :has_run, Boolean
  property :created_at, DateTime
  property :updated_at, DateTime
end
def Store_LogEntry(json_parsed)
    @duv_LogEntry = LogEntry.create(
      :type => json_parsed["LogEntry"]["type"],
      :message => json_parsed["LogEntry"]["message"],
      :file => json_parsed["LogEntry"]["file"]
      )
    @duv_LogEntry.save
    return @duv_LogEntry
end

def StoreResult(json_parsed)
      @duv_result = Result.create(
	:team => json_parsed["Result"]["team"],
	:run_date => DateTime.parse(json_parsed["Result"]["run_date"]),
	:academic_year => json_parsed["Result"]["academic_year"],
	:outcome => json_parsed ["Result"]["outcome"],
	:created_at => DateTime.parse(json_parsed ["Result"]["created_at"]),
	:updated_at => DateTime.parse(json_parsed ["Result"]["updated_at"]),
	:virtual => json_parsed ["Result"]["virtual"]
      )
      @duv_result.save     
      return @duv_result
end      
def StoreDesignResult(json_parsed)
    @duv_fail = Result.get!(json_parsed["DesignResult"]["id"]).design_results.create(
	:outcome => json_parsed["DesignResult"]["outcome"],
	:run_date => DateTime.parse(json_parsed["DesignResult"]["run_date"]),
	:created_at => DateTime.parse(json_parsed["DesignResult"]["created_at"]),
	:updated_at => DateTime.parse(json_parsed["DesignResult"]["updated_at"]),
	:file_name => json_parsed["DesignResult"]["file_name"],
	:clock_freq => json_parsed["DesignResult"]["clock_freq"],
	:design_name => json_parsed["DesignResult"]["design_name"] 
    )
    return @duv_fail
end
def StoreTestVectorResult(json_parsed)
    @duv_fail = DesignResult.get!(json_parsed["TestVectorResult"]["id"]).test_vector_results.create(
	:type => json_parsed["TestVectorResult"]["type"],
	:input_vector => json_parsed["TestVectorResult"]["input_vector"],
	:expected_result => json_parsed["TestVectorResult"]["expected_result"],
	:actual_result => json_parsed["TestVectorResult"]["actual_result"],
	:cycle_count => json_parsed["TestVectorResult"]["cycle_count"],
	:clock_freq => json_parsed["TestVectorResult"]["clock_freq"],
	:clock_connections => json_parsed["TestVectorResult"]["clock_connections"],
      	:bitmask => json_parsed["TestVectorResult"]["bitmask"],
	:dontcare_mask => json_parsed["TestVectorResult"]["dontcare_mask"],
	:trigger_mask => json_parsed["TestVectorResult"]["trigger_mask"],
	:outcome => json_parsed["TestVectorResult"]["outcome"],
	:trigger_timeout => json_parsed["TestVectorResult"]["trigger_timeout"],
	:has_run => json_parsed["TestVectorResult"]["has_run"],
	:created_at => DateTime.parse(json_parsed["TestVectorResult"]["created_at"]),
        :updated_at => DateTime.parse(json_parsed["TestVectorResult"]["updated_at"])
    )
    return @duv_fail
end
DataMapper.finalize




