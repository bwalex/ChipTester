require 'data_mapper'

#DataMapper.setup(:default, 'mysql://root:04123612775@localhost/ChipTester')
DataMapper.setup(:default, 'mysql://root@localhost/ChipTester')
#DataMapper.setup(:default, 'sqlite:test.db')
DataMapper::Logger.new($stdout, :debug)

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


def Store_DUV_Result(json_parsed)
      @duv_result = Result.create(
	:chip_number => json_parsed["Result"]["chip_number"],
	:team_number => json_parsed["Result"]["team_number"],
	:test_passed => json_parsed["Result"]["test_passed"],
	:file_name => json_parsed ["Result"]["file_name"],
	:frequency => json_parsed ["Result"]["frequency"],
	:temperature => json_parsed ["Result"]["temperature"]
      )
      @duv_result.save     
      return @duv_result
end      
def Store_DUV_Fail(json_parsed)
    @duv_fail = Result.get!(json_parsed["Fail"]["id"]).fails.create(
	:index => json_parsed["Fail"]["index"],
	:fail_result => json_parsed["Fail"]["fail_result"],
	:expected_result => json_parsed["Fail"]["expected_result"]
      )
    return @duv_fail
end
DataMapper.finalize
#DataMapper.auto_migrate!
#DataMapper.auto_upgrade!
