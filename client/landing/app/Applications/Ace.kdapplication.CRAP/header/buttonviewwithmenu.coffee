class Editor_ButtonViewWithMenu extends KDButtonViewWithMenu
  createContextMenu:(event)->
    @buttonMenu = new (@getOptions().buttonMenuClass or KDButtonMenu)
      cssClass : 'add-editor-menu'
      ghost    : @$('.chevron-arrow').clone()
      event    : event
      delegate : @

    for item in @options.menu
      @buttonMenu.addSubView menuTree = new (@getOptions().contextClass or KDContextMenuTreeView) delegate : @getDelegate()
      controller = new Editor_ContextMenuTreeViewController view : menuTree, item
      @listenTo 
        KDEventTypes : "itemsAdded"
        listenedToInstance : controller
        callback : ()=> @buttonMenu.positionContextMenu()

    KDView.appendToDOMBody @buttonMenu
    
  click:(event)->
    if $(event.target).is(".chevron-arrow") and @__shouldAdd
      @contextMenu event
      return no
    @getCallback().call @,event
    
  contextMenu:(event)->
    if $(event.target).is(".chevron-arrow") and @__shouldAdd
      @createContextMenu event
    no

