class FinderContextMenuTreeViewController extends KDContextMenuTreeViewController
  itemClass: (options, data)->
    switch data.type
      when 'divider'
        item = new KDContextMenuListItemSeparator options, data
      when 'permissionsSetter'
        item = new SetPermissionsMenuView options, data
      when 'addMount'
        $.extend options, delegate : @
        item = (new MountContextMenuListController options, data).contextMenuView
      else
        unless data.disabledForBeta
          item = new (@getOptions().subItemClass ? KDTreeItemView) options, data
          item.registerListener KDEventTypes : ['click'], callback : @clickOnMenuItem, listener : @
        else
          $.extend options, cssClass:'disabledForBeta'
          item = new DisabledFinderContextMenuItemView options, data
    item
    
  keyDownOnParent:(pubInst,event)=>
    super
    switch event.which
      when 13
        selectedItem = @selectedItems[0]
        @clickOnMenuItem selectedItem, event
        pubInst.hide()
  
  clickOnMenuItem:(source,event)=>
    source.data.callback?()
    contextMenuDelegate = @getView().delegate #context menu tree view delegate (item clicked)
    contextMenuDelegate.propagateEvent 
      KDEventType : 'ContextMenuFunction'
      globalEvent : yes
      {functionName : source.data.action, contextMenuDelegate, data:event}
