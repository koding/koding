class EditorAdvancedSettings_ButtonMenu extends KDButtonMenu
  aClick: (instance, event) ->
    if event.target.className is 'chevron-arrow-ghost'
      @destroy()
    else if instance.$().parents('.kdbuttonmenu').length is 0 and not instance.$().hasClass 'kdbuttonmenu'
      super

class EditorAdvancedSettings_ButtonViewWithMenu extends KDButtonViewWithMenu
  click:(event)->
    @contextMenu event
  
  createContextMenu:(event)->
    @buttonMenu = new (@getOptions().buttonMenuClass or KDButtonMenu)
      cssClass : @options.style
      ghost    : @$('.chevron-arrow').clone()
      event    : event
      delegate : @

    for item in @options.menu()
      @buttonMenu.addSubView menuTree = new (@getOptions().contextClass or KDContextMenuTreeView) delegate : @
      controller = new (@getOptions().contextControllerClass or KDContextMenuTreeViewController) view : menuTree, item
      @listenTo 
        KDEventTypes       : "itemsAdded"
        listenedToInstance : controller
        callback           : ()=> @buttonMenu.positionContextMenu()

    KDView.appendToDOMBody @buttonMenu

  performShowKeyboardHelper:->
    editorItems = [
      { keySet : "cmd+s",          title : "Save File" }
      { keySet : "cmd+shift+s",    title : "Save as..." }
      { keySet : "cmd+f",          title : "Find/Replace" }
      { keySet : "cmd+g",          title : "Find next" }
      { keySet : "cmd+b",          title : "Compile code" }
      { keySet : "cmd+e",          title : "Run code" }
      { keySet : "esc",            title : "Autocomplete" }
      { keySet : "shift+esc",      title : "Backwards autocomplete" }
      { keySet : "option+shift+q", title : "Close Editor" }
      { keySet : "option+shift+d", title : "Split Editor Vertically" }
      { keySet : "option+shift+c", title : "Split Editor Horizontally" }
    ]

    @_keyHelperModal.destroy() if @_keyHelperModal
    @_keyHelperModal = new KeyboardHelperModalView
      height    : "auto"
      position  :
        top     : 56
        right   : 5
      
    keyHelperController = new KDListViewController
      view    : new KeyboardHelperView
        title : "Editor Shortcuts"
    ,
      items   : editorItems

    @_keyHelperModal.addSubView keyHelperController.getView()
    
    @buttonMenu.destroy()
    (@getSingleton "windowController").scrollingEnabled = yes