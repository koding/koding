class KDContentEditableView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curryCssClass "kdcontenteditableview", options.cssClass
    options.bind = "click input keydown"
    super options, data
    options.placeholder ?= ""

    @getDelegate()?.on "EditingModeToggled", (state) => @setEditingMode state

    @validationNotifications = {}

  viewAppended: ->
    @setEditingMode off
    super

  getEditableElement: ->
    @editableElement = @getElement().children[0] unless @editableElement
    return  @editableElement

  getEditableDomElement: ->
    @editableDomElement = $ @getEditableElement() unless @editableDomElement
    return  @editableDomElement

  setEditingMode: (state) ->
    @editingMode = state
    @getEditableElement().setAttribute "contenteditable", state

    if @getValue() is ""
      if @editingMode then @setPlaceholder()
      else @unsetPlaceholder()

  getValue: ->
    value = @getEditableElement().textContent
    if value is @getOptions().placeholder then "" else Encoder.XSSEncode value

  setContent: (content) ->
    if not @editingMode and @getOptions().textExpansion
      content = @utils.applyTextExpansions content, yes

    element = @getEditableElement()
    if content then element.innerHTML = Encoder.XSSEncode content
    else if @editingMode then @setPlaceholder()

  focus: ->
    @getEditableDomElement().trigger "focus" unless @focused

    windowController = KD.getSingleton "windowController"
    windowController.addLayer this

    if @getValue().length is 0
      range = document.createRange()
      range.setStart @getEditableElement(), 0
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range

    @once "ReceivedClickElsewhere", @bound 'blur' unless @focused
    @focused = yes

  blur: ->
    @focused = no
    @setContent @getValue()
    if @getValue() is 0
      @setPlaceholder()

  click: => @focus() if @editingMode

  input: (event) => @emit "ValueChanged", event

  keyDown: (event) =>
    if event.which is 9 # Tab key
      event.preventDefault()
      @blur()
      if event.shiftKey then @emit "PreviousTabStop"
      else @emit "NextTabStop"
      return

    value = @getValue()
    maxLength = @getOptions().validate?.rules?.maxLength or 0

    if event.which is 13 or (maxLength > 0 and value.length == maxLength)
      event.preventDefault()
    else if value.length is 0
      @unsetPlaceholder()
      @focus()

  setPlaceholder: ->
    @setClass "placeholder"
    @setContent @getOptions().placeholder

  unsetPlaceholder: ->
    @unsetClass "placeholder"

    content = ""
    defaultValue = @getOptions().default
    value = @getValue()

    if @editingMode
      content = value or ""
    else
      content = value or defaultValue or ""

    @getEditableElement().textContent = content

  validate: (event) ->
    valid = yes
    for name, rule of @getOptions().validate?.rules or {}
      validator = KDInputValidator["rule#{name.capitalize()}"]
      if validator and message = validator @, event
        valid = no
        @notify message,
          title    : message
          type     : "mini"
          cssClass : "error"
          duration : 2500
        break
    return  valid

  notify: (message, options) ->
    @validationNotifications[message] = notice = new KDNotificationView options
    notice.on "KDObjectWillBeDestroyed", =>
      message = notice.getOptions().title
      delete @validationNotifications[message]
