kd                  = require 'kd'
KDView              = kd.View
KDHitEnterInputView = kd.HitEnterInputView
KDTabHandleView     = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  MIN_EDIT_WIDTH = 100

  constructor: (options = {}, data) ->

    options.draggable ?= yes
    options.bind       = 'dragstart dblclick'

    options.view = new KDView { tagName : 'span' }

    super options, data


  viewAppended: ->

    super

    { view, title }    = @getOptions()

    @titleText  = new KDView
      tagName  : 'b'
      cssClass : 'tab-handle-text'
      partial  : title
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

    @titleInput.on 'EscapePerformed', =>
      @setTitleEditMode no

    view.addSubView @titleInput


  setDraggable: ->

    @setAttribute 'draggable', yes


  dragStart: (event) ->

    ## workaround for FF and ChromeApp
    event.originalEvent.dataTransfer.setData 'text/plain', ' '

    kd.singletons.appManager.tell 'IDE', 'setTargetTabView', @getDelegate()


  makeEditable: -> @isEditable = yes


  dblClick: ->

    return  unless @isEditable and @getWidth() >= MIN_EDIT_WIDTH
    return  if @hasClass 'edit-mode'

    @setTitleEditMode yes


  setTitleEditMode: (isEditMode) ->

    { title } = @getOptions()
    if isEditMode
      @setClass 'edit-mode'
      @titleInput.setValue title
      @titleInput.setFocus()
    else
      @unsetClass 'edit-mode'


  setTitle: (newTitle) ->

    { addTitleAttribute } = @getOptions()

    @setOption 'title', newTitle
    @titleText.updatePartial newTitle
    @getElement().setAttribute 'title', newTitle  if addTitleAttribute

    @setTitleEditMode no
