#DataMapper.setup(:default, 'mysql://root:04123612775@localhost/ChipTester')
DataMapper.setup(:default, 'mysql://root:04123612775@localhost/ChipTester')
class DUV_Descriptor
  include DataMapper::Resource
  
  property :id, Serial  # An auto-increment integer key
  property :chip_number, Integer,:required => true # The number of the chip
  property :team_number, Integer      # The number of the team
  property :configure_date, DateTime  # A DateTime, for any date you might like.
end

class Result
  include DataMapper::Resource
  property :id, Serial  # An auto-increment integer key
  #property :id_test, Integer
  property :chip_number, Integer, :required => true #The number of the chip
  property :team_number, Integer 
  property :test_passed, Boolean, :required => true #If the test passed or not
  property :file_name, String #File name of the test

  has n, :fails
end

class Fail
  include DataMapper::Resource
  property :id, Serial
 # property :id_test, Integer
  property :index, Integer
  property :fail_result, String, :required => true
  property :expected_result, String, :required => true
  belongs_to :result
end

def Store_DUV_Result(json_parsed)
      @duv_result = Result.create(
	:chip_number => json_parsed["Result"]["chip_number"],
	:team_number => json_parsed["Result"]["team_number"],
	:test_passed => json_parsed["Result"]["test_passed"],
	:file_name => json_parsed ["Result"]["file_name"]
      )
      @duv_result.save     
      return @duv_result.id
end      
def Store_DUV_Fail(json_parsed)
    @duv_fail = Fail.create(
	:index => json_parsed["Fail"]["index"],
	:fail_result => json_parsed["Fail"]["fail_result"],
	:expected_result => json_parsed["Fail"]["expected_result"]
      )
    @duv_fail.save
end
DataMapper.finalize
#DataMapper.auto_migrate!
DataMapper.auto_upgrade!