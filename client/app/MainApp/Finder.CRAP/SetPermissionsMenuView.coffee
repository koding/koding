class SetPermissionsMenuView extends KDTreeItemView
  constructor:(options,data)->
    super options,data
    @addSubView x = new SetPermissionsView cssClass : "set-permissions-wrapper", delegate: @, file: @getDelegate().getDelegate()

  partial:(data)-> ""

  click:(event)->
    no
  
  getItemView:->
    contextMenu = @getDelegate()
    itemView    = contextMenu.getDelegate()
    
  set: (permissions, recursive) ->
    @getItemView().performSetPermissions? permissions, recursive
  
  fetch:(callback)->
    @getItemView().fetchPermissions callback