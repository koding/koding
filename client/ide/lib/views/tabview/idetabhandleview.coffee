kd              = require 'kd'
KDView          = kd.View
KDInputView     = kd.InputView
KDTabHandleView = kd.TabHandleView


module.exports = class IDETabHandleView extends KDTabHandleView

  ENTER = 13
  ESC   = 27

  MIN_EDIT_WIDTH = 100

  constructor: (options = {}, data) ->

    options.draggable ?= yes
    options.bind       = 'dragstart dblclick'

    options.view = new KDView { tagName : 'span' }

    super options, data


  viewAppended: ->

    super

    { view, title }    = @getOptions()

    @titleText  = new KDView { tagName : 'b', partial : title }
    view.addSubView @titleText

    @titleInput = new KDInputView
      type    : 'text'
      keydown : (event) =>
        switch event.which
          when ESC then @setTitleEditMode no
          when ENTER
            { title } = @getOptions()
            newTitle  = @titleInput.getValue()

            return  unless newTitle.length

            @emit 'RenamingRequested', newTitle, title

    @titleInput.hide()
    view.addSubView @titleInput


  setDraggable: ->

    @setAttribute 'draggable', yes


  dragStart: (event) ->

    ## workaround for FF and ChromeApp
    event.originalEvent.dataTransfer.setData 'text/plain', ' '

    kd.singletons.appManager.tell 'IDE', 'setTargetTabView', @getDelegate()


  makeEditable: -> @isEditable = yes


  dblClick: ->

    return  unless @isEditable and @getWidth() > MIN_EDIT_WIDTH
    return  unless @titleInput.hasClass 'hidden'

    @setTitleEditMode yes


  setTitleEditMode: (isEditMode) ->

    { title } = @getOptions()
    if isEditMode
      @titleText.hide()
      @titleInput.setValue title
      @titleInput.show()
      @titleInput.setFocus()
    else
      @titleText.show()
      @titleInput.hide()


  setTitle: (newTitle) ->

    { addTitleAttribute } = @getOptions()

    @setOption 'title', newTitle
    @titleText.updatePartial newTitle
    @getElement().setAttribute 'title', newTitle  if addTitleAttribute

    @setTitleEditMode no
