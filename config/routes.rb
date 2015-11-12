match 'adburndown/(:action(/:id))', :controller => 'adburndown', :via => [:get, :post]
match 'adsprintinl/(:action(/:id))', :controller => 'adsprintinl', :via => [:get, :post]
match 'adsprints/(:action(/:id))', :controller => 'adsprints', :via => [:get, :post]
match 'adtaskinl/(:action(/:id))', :controller => 'adtaskinl', :via => [:get, :post]
match 'adtasks/(:action(/:id))', :controller => 'adtasks', :via => [:get, :post]
match 'all_sprints/(:action(/:id))', :controller => 'all_sprints', :via => [:get, :post]
resources :custom_field_types, only: [:create, :destroy]
resources :sprint_custom_fields, only: [:update] do
  collection do
    put '' => :update_by_type, as: :update_by_type
  end
end
