class Results_Bind
  def initialize(configuration, results, fail)
    @configuration = configuration
    @results = results
    @fail = fail
  end

  def get_binding
    return binding()
  end
end