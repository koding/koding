class WebTermView extends KDView

  setDefaultStyle:->
    @container.unsetClass font.value for font in __webtermSettings.fonts
    @container.unsetClass theme.value for theme in __webtermSettings.themes
    @container.setClass @appStorage.getValue('font') or 'ubuntu-mono'
    @container.setClass @appStorage.getValue('theme') or 'green-on-black'
    @container.$().css fontSize:@appStorage.getValue('fontSize')+'px' or '14px'
  viewAppended: ->

    @appStorage = new AppStorage 'WebTerm', '1.0'


    @container = new KDView
      cssClass : "console ubuntu-mono black-on-white"
    @addSubView @container

    @appStorage.fetchStorage (storage)=>
      @setDefaultStyle()

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
      itemClass: WebTermSessionItem
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

    @terminal = new WebTerm.Terminal @container.$()

    @advancedSettings = new KDButtonViewWithMenu
      style         : 'editor-advanced-settings-menu'
      icon          : yes
      iconOnly      : yes
      iconClass     : "cog"
      type          : "contextmenu"
      delegate      : @
      itemClass     : WebtermSettingsView
      click         : (pubInst, event)-> @contextMenu event
      menu          : @getAdvancedSettingsMenuItems.bind @

    @addSubView @advancedSettings

    @terminal.sessionEndedCallback = (sessions) =>
      @emit "WebTerm.terminated"
      return

      @server.getSessions (sessions) =>
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
    @terminal.setTitleCallback = (title) =>
      #@tabPane.setTitle title

    @listenWindowResize()

    @focused = true

    @on "ReceivedClickElsewhere", =>
      @focused = false
      @terminal.setFocused false
      @getSingleton('windowController').removeLayer @

    $(window).bind "blur", =>
      @terminal.setFocused false

    $(window).bind "focus", =>
      @terminal.setFocused @focused

    $(document).on "paste", (event) =>
      @terminal.server.input event.originalEvent.clipboardData.getData("text/plain") if @focused
      @setKeyView()

    @bindEvent 'contextmenu'

    KD.singletons.kiteController.run
      kiteName: 'webterm',
      method: 'createSession',
      withArgs:
        remote: @terminal.clientInterface
        name: "none"
        sizeX: @terminal.sizeX
        sizeY: @terminal.sizeY
    , (err, remote) =>
      @terminal.server = remote
      @setKeyView()

  destroy: ->
    super
    @terminal.server?.close()

  setKeyView: ->
    super
    @getSingleton('windowController').addLayer @
    @focused = true
    @terminal.setFocused true

  click: ->
    @setKeyView()
    @textarea?.remove()

  keyDown: (event) ->
    @terminal.keyDown event

  keyPress: (event) ->
    @terminal.keyPress event

  keyUp: (event) ->
    @terminal.keyUp event

  contextMenu: (event) ->
    # invisible textarea will be placed under the cursor when rightclick
    @createInvisibleTextarea event
    @setKeyView()
    event

  createInvisibleTextarea:(eventData)->

    # Get selected Text for cut/copy
    if window.getSelection
        selectedText = window.getSelection()
    else if document.getSelection
        selectedText = document.getSelection()
    else if document.selection
        selectedText = document.selection.createRange().text

    @textarea?.remove()
    @textarea = $(document.createElement("textarea"))
    @textarea.css
      position  : "absolute"
      opacity   : 0
      # width     : "30px"
      # height    : "30px"
      # top       : eventData.offsetY-10
      # left      : eventData.offsetX-10
      width       : "100%"
      height      : "100%"
      top         : 0
      left        : 0
      right       : 0
      bottom      : 0
    @$().append @textarea

    # remove on any of these events
    @textarea.on 'copy cut paste', (event)=>
      @setKeyView()
      @utils.wait 1000, => @textarea.remove()
      yes

    if selectedText
      @textarea.val(selectedText.toString())
      @textarea.select()
    @textarea.focus()

    #remove 15sec later
    @utils.wait 15000, =>
      @textarea?.remove()

  _windowDidResize: (event) ->
    @terminal.windowDidResize()

  getAdvancedSettingsMenuItems:->

    settings      :
      type        : 'customView'
      view        : new WebtermSettingsView
        delegate  : @


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