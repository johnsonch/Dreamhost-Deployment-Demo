set :user, 'YOUR_DH_USERNAME'
set :application, "deployment-demo.johnsonch.com" 
set :repository, "git://github.com/johnsonch/Dreamhost-Deployment-Demo.git" 
set :scm, :git

# =============================================================================
# You shouldn't have to modify the rest of these
# =============================================================================

role :web, application
role :app, application
role :db,  application, :primary => true

set :deploy_to, "/home/#{user}/#{application}" 
# set :svn, "/path/to/svn"       # defaults to searching the PATH
set :use_sudo, false
# set :restart_via, :run


# saves space by only keeping last 3 when running cleanup
set :keep_releases, 3 

# issues svn export instead of checkout
set :checkout, "export" 
set :copy_strategy, :export

# keeps a local checkout of the repository on the server to get faster deployments
#set :deploy_via, :copy

ssh_options[:paranoid] = false

# =============================================================================
# OVERRIDE TASKS
# =============================================================================
namespace :deploy do
    desc "Restart Passenger" 
    task :restart, :roles => :app do
      run "touch #{current_path}/tmp/restart.txt" 
    end
  
      task :after_update_code, :roles => :app do 
          #rcov messes with deployed apps...
          run "rm -rf #{release_path}/vendor/plugins/rails_rcov" 
        end

    desc <<-DESC
      Deploy and run pending migrations. This will work similarly to the \
      `deploy' task, but will also run any pending migrations (via the \
      `deploy:migrate' task) prior to updating the symlink. Note that the \
      update in this case it is not atomic, and transactions are not used, \
      because migrations are not guaranteed to be reversible.
    DESC
  

    task :migrations do
      set :migrate_target, :latest
      update_code
      symlink
      migrate
      restart
    end

  end

  db_params = {
    "adapter"=>"mysql",
    "database"=>"YOUR_DATABASE",
    "username"=>"YOUR_MYSQL_USERNAME",
    "password"=>"YOUR_PASSWORD",
    "host"=>"mysql.YOUR_HOST.com",
    "socket"=>""
  }

  task :my_generate_database_yml, :roles => :app do
    database_configuration = "production:\n"
    db_params.each do |param, default_val|
      database_configuration<<"  #{param}: #{default_val}\n"
    end
    run "mkdir -p #{deploy_to}/#{shared_dir}/config"
    put database_configuration, "#{release_path}/config/database.yml"
  end
  after "deploy:symlink", :my_generate_database_yml
  




  ##/public/user_uploads/cms/images
  task :symlink_uploads do
    # run "mkdir -p #{deploy_to}/#{current_dir}/public/user_uploads/"
    run "ln -s #{deploy_to}/#{shared_dir}/user_uploads #{deploy_to}/#{current_dir}/public/"
  end  
  after "deploy:symlink", :symlink_uploads



