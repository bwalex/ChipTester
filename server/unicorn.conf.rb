worker_processes 1
#working_directory @dir

preload_app true

timeout 30
listen 4567


# Set the path of the log files inside the log folder of the testapp
#stderr_path "/var/rails/testapp/log/unicorn.stderr.log"
#stdout_path "/var/rails/testapp/log/unicorn.stdout.log"

before_fork do |server, worker|
end

after_fork do |server, worker|
end
