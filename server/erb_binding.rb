class Results_Bind
  def initialize(configuration, results, results_fail)
    @configuration = configuration
    @results = results
    @results_fail
  end

  def get_binding
    return binding()
  end
end