class MountContextMenuListController extends KDListViewController
  constructor:(options,data)->
    super options, data
    
    @contextMenuView = new KDTreeItemView options, data
    @contextMenuView.addSubView @getView()
  
  loadView:(mainView)->
    visitor = @getSingleton('mainController').getVisitor().currentDelegate
    
    visitor.fetchMounts (err,mounts)=>
      if err then warn err
      else
        @instantiateListItems mounts
  
  instantiateListItems:(items)->
    @contextMenuView.updatePartial '','.default'
    super
  
  itemClass:(options,data)->
    itemView = new (@getOptions().subItemClass ? MountContextMenuListItemView) options, data
    itemView.registerListener KDEventTypes : "click", listener : @, callback:->
      @getDelegate().clickOnMenuItem (data : action : 'addMount'), data
    itemView
