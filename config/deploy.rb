require 'net/ssh/proxy/http'
behind_firewall = false # set me dynamically in the future!
if behind_firewall
  proxy = Net::SSH::Proxy::HTTP.new( "itgproxy.redmond.corp.microsoft.com", 80 )
  ssh_options[:proxy] = proxy
end

set :application, "whiskey.brightshiny.me"
set :repository,  "ssh://brightshiny.me:443/home/whiskey/git/whiskey.git"
set :user, "nick"
set :use_sudo, true

set :keep_releases, 3

ssh_options[:port] = 443
ssh_options[:forward_agent] = true 
default_run_options[:pty] = true 

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :deploy_via, :remote_cache

role :app, application
role :web, application
role :db,  application, :primary => true

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
