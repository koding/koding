class Editor_BottomBar extends KDView
  constructor:(options,data)->
    super
    @setClass "editor-bottom-bar clearfix"

  viewAppended:()->
    @addSubView infoBar = new Editor_BottomBar_Info
    # @addSubView terminal = new Editor_BottomBar_Terminal
    @addSubView settingsButton = new EditorAdvancedSettings_ButtonViewWithMenu
      style                   : 'editor-advanced-settings-menu'
      icon                    : yes
      iconOnly                : yes
      iconClass               : "cog"
      delegate                : @
      contextControllerClass  : EditorAdvancedSettings_ContextMenu
      buttonMenuClass         : EditorAdvancedSettings_ButtonMenu
      menu                    : => @getAdvancedMenu()
      callback                : (event)-> settingsButton.contextMenu event

    @addSubView splitButton = new KDButtonViewWithMenu
      style                   : 'editor-advanced-settings-menu split-view-button'
      title                   : ''
      icon                    : yes
      delegate                : @
      iconClass               : "plus-black"
      menu                    : => @splitMenu()
      callback                : (event)-> splitButton.contextMenu event

    @listenTo
      KDEventTypes: 'EditorChangeCursorPosition'
      listenedToInstance: @getDelegate()
      callback: (pubInst, {row, column}) =>
        infoBar.setRow row
        infoBar.setColumn column

  splitMenu:->
    [
      type : "contextmenu"
      items : [
        { title : '<span>&rarr;</span> Split right',  id : 1,  parentId : null, callback: => @splitRight.apply @, arguments}
        { title : '<span>&larr;</span> Split left',   id : 2,  parentId : null, callback: => @splitLeft.apply @, arguments }
        { title : '<span>&uarr;</span> Split top',    id : 3,  parentId : null, callback: => @splitTop.apply @, arguments }
        { title : '<span>&darr;</span> Split bottom', id : 4,  parentId : null, callback: => @splitBottom.apply @, arguments }
      ]
    ]

  getAdvancedMenu: ->
    editor = @getDelegate()
    menu =
      type : "contextmenu"
      items : [
        { title : 'Use soft tabs',                 id : 1,  parentId : null, type : 'switch',    default: (=> editor.getUseSoftTabs()),          callback: (state) -> editor.setUseSoftTabs            state }
        { title : 'Show gutter',                   id : 2,  parentId : null, type : 'switch',    default: (-> editor.getShowGutter()),           callback: (state) -> editor.setShowGutter             state }
        { title : 'Show print margin',             id : 3,  parentId : null, type : 'switch',    default: (-> editor.getShowPrintMargin()),      callback: (state) -> editor.setShowPrintMargin        state }
        { title : 'Highlight active line',         id : 4,  parentId : null, type : 'switch',    default: (-> editor.getHighlightActiveLine()),  callback: (state) -> editor.setHighlightActiveLine    state }
        { title : 'Highlight selected word',       id : 5,  parentId : null, type : 'switch',    default: (-> editor.getHighlightSelectedWord()),callback: (state) -> editor.setHighlightSelectedWord  state }
        { title : 'Show invisibles',               id : 6,  parentId : null, type : 'switch',    default: (-> editor.getShowInvisibles()),       callback: (state) -> editor.setShowInvisibles         state }
        { type  : 'divider' }
        { title : 'Soft wrap',                     id : 7,  parentId : null, type : 'softwrap',  default: (-> editor.getUseWrapMode()),          callback: (state) -> editor.setUseWrapMode            state }
      ]                                           
    menu.items.push title: 'Syntax',               id : 8,  parentId : null, type : 'element',   default: (-> editor.getActiveSyntaxName()),     element: new Editor_BottomBar_SyntaxSelector   (delegate: @)
    menu.items.push title: 'Font',                 id : 9,  parentId : null, type : 'element',   default: (-> editor.getFontSize()),             element: new Editor_BottomBar_FontSizeSelector (delegate: @)
    menu.items.push title: 'Theme',                id : 10, parentId : null, type : 'element',   default: (-> editor.getTheme()),                element: new Editor_BottomBar_ThemeSelector    (delegate: @)
    menu.items.push title: 'Tab size',             id : 11, parentId : null, type : 'element',   default: (-> editor.getTabSize()),              element: new Editor_BottomBar_TabSizeSelector  (delegate: @)
    menu.items.push title: '⌘ Keyboard Shortcuts', id : 13, parentId : null, type : 'keyboard',  function : "showKeyboardHelper"

    [menu]

  splitRight: ->
    editor = @getDelegate()
    editor.propagateEvent KDEventType: 'EditorSplit', {splitType: 'vertical', direction: 'right'}
    
  splitLeft: ->
    editor = @getDelegate()
    editor.propagateEvent KDEventType: 'EditorSplit', {splitType: 'vertical', direction: 'left'}
    
  splitTop: ->
    editor = @getDelegate()
    editor.propagateEvent KDEventType: 'EditorSplit', {splitType: 'horizontal', direction: 'top'}
    
  splitBottom: ->
    editor = @getDelegate()
    editor.propagateEvent KDEventType: 'EditorSplit', {splitType: 'horizontal', direction: 'bottom'}
