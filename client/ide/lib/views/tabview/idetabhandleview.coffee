kd                  = require 'kd'
KDView              = kd.View
KDHitEnterInputView = kd.HitEnterInputView
KDTabHandleView     = kd.TabHandleView
KDCustomHTMLView    = kd.CustomHTMLView
IDEEditorPane       = require 'ide/workspace/panes/ideeditorpane'
FSHelper            = require 'app/util/fs/fshelper'
Encoder             = require 'htmlencode'


module.exports = class IDETabHandleView extends KDTabHandleView

  MIN_EDIT_WIDTH = 100

  constructor: (options = {}, data) ->

    options.draggable ?= yes
    options.bind       = 'dragstart dblclick dragend'
    options.view       = new KDView
      tagName : 'span'
      cssClass: 'tab-handle-tabname'

    { pane } = options

    if pane?.view instanceof IDEEditorPane and not pane.data.isDummyFile()
      options.attributes = { title : FSHelper.plainPath pane.data.path }

    super options, data


  viewAppended: ->

    super

    return  if @titleText

    { view, title, pane } = @getOptions()

    @titleText  = new KDView
      tagName  : 'b'
      cssClass : 'tab-handle-text'
      partial  : Encoder.XSSEncode title

    view.addSubView @titleText

    @titleInput = new KDHitEnterInputView
      type     : 'text'
      cssClass : 'tab-handle-input'

    @titleInput.on 'EnterPerformed', =>
      { title } = @getOptions()
      newTitle  = @titleInput.getValue()

      return  unless newTitle.length
      return @setTitleEditMode no  if newTitle is title

      @emit 'RenamingRequested', newTitle, title

    @titleInput.on 'EscapePerformed', @lazyBound 'setTitleEditMode', no

    view.addSubView @titleInput

    @on 'dblclick', @lazyBound 'setTitleEditMode', yes
    @on 'ReceivedClickElsewhere', @lazyBound 'setTitleEditMode', no


  setDraggable: ->

    @setAttribute 'draggable', yes


  dragStart: (event) ->

    ## workaround for FF and ChromeApp
    event.originalEvent.dataTransfer.setData 'text/plain', ' '

    kd.singletons.appManager.tell 'IDE', 'setTargetTabView', @getDelegate()


  dragEnd: ->

    kd.singletons.appManager.tell 'IDE', 'resetDragState'


  makeEditable: -> @isEditable = yes


  setTitleEditMode: (isEditMode) ->

    { title } = @getOptions()
    { windowController } = kd.singletons

    if isEditMode
      return  unless @isEditable and @getWidth() >= MIN_EDIT_WIDTH
      return  if @hasClass 'edit-mode'

      @setClass 'edit-mode'
      @titleInput.setValue title
      @titleInput.setFocus()

      lastIndex = title.lastIndexOf('.')
      if lastIndex > 0
        @titleInput.selectRange 0, lastIndex
      else
        @titleInput.selectAll()
      windowController.addLayer this
    else
      @unsetClass 'edit-mode'
      windowController.removeLayer this


  setTitle: (newTitle) ->

    { addTitleAttribute } = @getOptions()

    @setOption 'title', newTitle
    @titleText.updatePartial newTitle
    @getElement().setAttribute 'title', newTitle  if addTitleAttribute

    @setTitleEditMode no


  enableContextMenu: ->

    @icon?.destroy()

    @icon = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'options'
      click    : => @createMenu @icon

    @addSubView @icon, null, yes


  createMenu: (icon) ->

    @setClass 'menu-visible'
    menu = kd.getSingleton('appManager').tell 'IDE', 'showStatusBarMenu', this, icon

    kd.utils.defer =>
      @menu.once 'KDObjectWillBeDestroyed', =>
        @unsetClass 'menu-visible'
        @menu = null
