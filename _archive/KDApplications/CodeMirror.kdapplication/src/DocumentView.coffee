class DocumentView extends KDView
  constructor:(options,data)->
    options.cssClass = 'code-mirror'
    super options, data
  
  getName:->
    @getOptions().name
  
  viewAppended:->  
    @addSubView new DocumentTopBar delegate : @
    @addSubView new KDView
      cssClass    : 'code-mirror-wrapper'
    @addSubView @bottomBar = new DocumentBottomBar delegate : @
    super
  
  getBottomBar:->
    @bottomBar


class DocumentBottomBar extends KDView
  constructor:(options,data)->
    options.cssClass = "editor-bottom-bar clearfix"
    super options, data

  viewAppended:()->
    delegate = @getDelegate()
    
    @addSubView @infoBar              = new DocumentCursorPosition
    @addSubView rightWrapper         = new KDView cssClass : "bottom-right-wrapper clearfix"
    
    rightWrapper.addSubView button = new KDButtonViewWithMenu
      style                   : 'editor-advanced-settings-menu'
      title                   : ''
      icon                    : yes
      delegate                : @
      iconClass               : "cog-white"
      callback                : -> delegate.propagateEvent KDEventType : 'AdvancedSettingClick', button
    super
  
  updateCursorPosition:(row, column)->
    {infoBar} = @
    infoBar.setRow row
    infoBar.setColumn column
    


class DocumentCursorPosition extends KDView
  constructor: (options, data) ->
    options               =   options ? {}
    options.lineNumber    or= 0
    options.columnNumber  or= 0
    options.cssClass      = "cursor-position"
    super options, data

  partial: ->
    options = @getOptions()
    "
    <div class='line-number'>Line: #{options.lineNumber}</div>
    <div class='column-number'>Column: #{options.columnNumber}</div>
    "

  viewAppended: ->
    @refresh()

  setRow: (lineNumber = 0) ->
    @getOptions().lineNumber = ++lineNumber
    @refresh()

  setColumn: (columnNumber = 0) ->
    @getOptions().columnNumber = ++columnNumber
    @refresh()

  refresh: ->
    @$().html ''
    @setPartial @partial()

class DocumentTopBar extends KDView
  constructor:(options,data)->
    options.cssClass = 'editor-header top-bar clearfix'
    super options,data

  viewAppended:()->
    delegate = @getDelegate()
    @addSubView buttonView = new KDButtonViewWithMenu
      title     : "Save"
      style     : "clean-gray editor-button save-menu"
      delegate  : @
      menu      : [
        items : [
          {title : "Save as...",      id : 13,  parentId : null, function : "saveFileAs" }
        ]
      ]
      callback  : -> delegate.propagateEvent KDEventType : 'DocumentSaveClick'
    buttonView.registerListener KDEventTypes : 'ContextMenuFunction', listener : @, callback : ->delegate.propagateEvent KDEventType : 'DocumentSaveAsClick'