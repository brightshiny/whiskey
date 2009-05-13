ActionController::Routing::Routes.draw do |map|

  # map.resources :clicks
  # map.resources :reads

  map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'
  map.login '/login', :controller => 'user_sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.account '/account', :controller => 'users', :action => 'show'
  # 
  # map.open_id_complete 'session', :controller => "sessions", :action => "create", :requirements => { :method => :get }
  # 
  
  map.resource :account, :controller => "users"
  map.resources :password_resets
  map.resources :users
  map.resource :user_session
  
  map.resources :feeds
  
  map.connect '/site/current', :controller => "site", :action => "current"
  map.resources :site
  
  map.thanks '/thanks', :controller => 'users', :action => 'thanks'
  map.verify '/verify/:perishable_token', :controller => 'activations', :action => 'new'
  map.activate '/activate/:perishable_token', :controller => 'activations', :action => 'create'
  
  map.root :controller => "site", :action => "index"

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  map.root :controller => "users"

  map.high_priority_feed "/feed/high/:u", :controller => "list_of_items", :action => "index"
  map.medium_priority_feed "/feed/medium/:u", :controller => "list_of_items", :action => "index"
  map.low_priority_feed "/feed/low/:u", :controller => "list_of_items", :action => "index"
  
  map.scroll "/scroll/:u", :controller => "list_of_items", :action => "scroll"

  map.connect "/c/:i/:t", :controller => "clicks", :action => "create"
  map.connect "/c/:i", :controller => "clicks", :action => "create"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
