class SidebarController extends KDViewController
  
  accountChanged:(account)->
    
    {profile} = account
    sidebar   = @getView()

    sidebar.render account