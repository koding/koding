class CollaborativeClientTerminalPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "webterm client-webterm"

    super options, data

    panel              = @getDelegate()
    workspace          = panel.getDelegate()
    {@sessionKey}      = @getOptions()
    @workspaceRef      = workspace.firepadRef.child @sessionKey
    @focusedToTextarea = no

    log "i am a client fake terminal and my session key is #{@sessionKey}"

    @workspaceRef.on "value", (snapshot) =>
      encoded = snapshot.val()?.terminal
      return  unless encoded

      @container.updatePartial JSON.parse(window.atob(encoded)).join "<br />"

    @createElements()
    @blinkCursor()

  createElements: ->
    @container  = new KDView
      cssClass  : "console ubuntu-mono green-on-black pane"
      click     : @bound "focusToTextarea"

    @textarea   = new KDInputView
      type      : "textarea"
      keypress  : @bound "handleKey"
      keyup     : @bound "handleKey"

  focusToTextarea: ->
    @textarea.setFocus()
    @focusedToTextarea = yes

  blinkCursor: ->
    containerDomElement = @container.domElement
    KD.utils.repeat 600, =>
      if @focusedToTextarea
        inverse  = containerDomElement.find ".inverse"
        outlined = containerDomElement.find ".outlined"
        element  = if inverse?.length then inverse else if outlined.length then outlined
        element.toggleClass "inverse"

  handleKey: (event) ->
    value = @textarea.getValue()

    log "client terminal value changed to", value

    keyEvent = {}
    codes    = [ "key"     , "char"   , "charCode", "keyCode", "which" ]
    specials = [ "shiftKey", "metaKey", "altKey"  , "ctrlKey"          ]

    log "original event is", event

    keyEvent[code] = event[code] or 0  for code in codes
    keyEvent[spec] = event[spec] or no for spec in specials
    keyEvent.type  = event.type

    log "registering a key event object to firebase", keyEvent
    @workspaceRef.set "keyEventFromClient": keyEvent

  pistachio: ->
    """
      {{> @container}}
      {{> @textarea}}
    """