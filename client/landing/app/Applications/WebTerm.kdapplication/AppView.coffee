class WebTermView extends KDView
  viewAppended: ->
    @container = new KDView
      cssClass : "console"
    @addSubView @container
    
    @sessionBox = new KDView
      cssClass: "kddialogview"
      position:
        top: 10
        left: 10
    @sessionBox.hide()
    @addSubView @sessionBox
    
    label = new KDLabelView
      title: "Select session:"
    @sessionBox.addSubView label

    @sessionList = new KDListView
      subItemClass: WebTermSessionItem
    @sessionBox.addSubView @sessionList
    
    label = new KDLabelView
      title: "Create session with name:"
    @sessionBox.addSubView label
    
    sessionNameInput = new KDInputView
      label: label
      defaultValue: (new Date).format "yyyy-mm-dd HH:MM:ss"
    @sessionBox.addSubView sessionNameInput
    
    createSessionButton = new KDButtonView
      title: "Create"
      callback: =>
        @sessionBox.hide()
        @terminal.createSession sessionNameInput.getValue()
        @setKeyView()
    @sessionBox.addSubView createSessionButton
    
    @listenWindowResize()
    
    @on "ReceivedClickElsewhere", =>
      @terminal.setFocused false
      @getSingleton('windowController').removeLayer @

    # $(window).bind "focus", =>
    #   @terminal.setFocused true
    
    # $(window).bind "blur", =>
    #   @terminal.setFocused false
    
    KD.whoami().tellKite
      kiteName: 'webterm',
      method: 'connectionInitializationDummy'
    
    window.setTimeout =>
      @terminal = new WebTerm.Terminal @container.$(), (sessions) =>
        keys = Object.keys sessions
        keys.sort (a, b) ->
          if sessions[a] < sessions[b]
            -1
          else if sessions[a] > sessions[b]
            1
          else
            0
        @sessionList.empty()
        for key in keys
          @sessionList.addItem
            id: parseInt(key)
            name: sessions[key]
            mainView: this
        @sessionBox.show()

      KD.whoami().tellKite
        kiteName: 'webterm',
        method: 'createServer',
        withArgs: @terminal.clientInterface
      , (remote) =>
        @terminal.server = remote
        @terminal.showSessions()
    , 3000
  
  setKeyView:->
    @getSingleton('windowController').addLayer @
    # checking existence of terminal because of the initial timeout
    # this may run before it is created
    @terminal.setFocused true if @terminal
    super

  click: ->
    @setKeyView()
    
  keyDown: (event) ->
    @terminal.keyDown event
  
  keyPress: (event) ->
    @terminal.keyPress event
  
  keyUp: (event) ->
    @terminal.keyUp event
  
  _windowDidResize: (event) ->
    @terminal.windowDidResize()

class WebTermSessionItem extends KDListItemView
  constructor: (options = {},data) ->
    super options, data
  
  partial: (data) ->
    link = $(document.createElement("a"))
    link.text data.name
    link.attr "href", "#"
    link.bind "click", (event) =>
      data.mainView.sessionBox.hide()
      data.mainView.terminal.joinSession data.id
      event.preventDefault()
    link