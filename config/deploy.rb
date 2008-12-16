require 'net/ssh/proxy/http'

# Configure this appropriately for your present local location
behind_firewall = false # set me dynamically in the future!
if behind_firewall
  proxy = Net::SSH::Proxy::HTTP.new( "itgproxy.redmond.corp.microsoft.com", 80 )
  ssh_options[:proxy] = proxy
end

# Remote server / file info 
set :application, "whiskey.brightshiny.me"
set :deploy_to, "/var/www/#{application}"
ssh_options[:port] = 443
ssh_options[:forward_agent] = true 

# Should we use "whiskey" + ssh_keys?  thoughts?
set :user, "nick" 
set :use_sudo, true

# We're using git and we want to deploy using the remote cache (to prevent .git dirs / etc)
set :scm, :git
set :deploy_via, :remote_cache
set :repository,  "ssh://brightshiny.me:443/home/whiskey/git/whiskey.git"

# Number of releases to leave on server including the currently live version
set :keep_releases, 3

# Forces more passwords to be entered but prevents git from mistaking your account
default_run_options[:pty] = true 

# The location of our 3 servers
role :app, application
role :web, application
role :db,  application, :primary => true

# An extra task for restarting Phusion-based apps (though I don't think it works)
namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

# namespace :passenger do  
#   desc "Restart Application"  
#   task :restart do  
#     run "touch #{current_path}/tmp/restart.txt"  
#   end  
# end    
# after :deploy, "passenger:restart"  
