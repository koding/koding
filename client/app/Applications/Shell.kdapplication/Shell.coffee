class ShellView extends KDView

  constructor:() ->
    super
    @setClass "terminal-tab"
    @$().css "overflow","auto"
    @listenWindowResize()
    @clientType = "anyterm.js"
  viewAppended:->
    @addSubView @screen = new KDCustomHTMLView tagName:'pre',cssClass:"terminal-screen"
    @addSubView @input = new ShellInputView bind: "paste", position : top: -4000, left: -4000
    @addSubView @controllMenu = new Shell_UIControls cssClass:"shell-advanced-settings-wrapper", delegate:@
    @initiateClient()
    super
  destroy:()->
    @removeSubView @screen
    @removeSubView @input
    @removeSubView @controllMenu
    if @client
      @client.setError ""
      delete @client
  disableInput:()->
    @input.stop()
  initiateClient:(type)->
    if not type? then type = @clientType else @clientType = type
    @screen.updatePartial ""
    if @client
      delete @client
    clientOptions = 
      view: @screen
      size: @calculateSize()
      handler: ()->
    @client = new TerminalClient clientOptions
    @input.setHandler @client
    @input.setFocus()
  reset:(type)->
    @initiateClient type
  click: ->
    @input.setFocus()

  updateScreen:(data)->

    if @client
      @client.write data
    else
      console.log "err: no @client"

  _windowDidResize: ->

    @client?.resize @calculateSize()
    @emit "ViewResized"

  calculateSize: ->
    obj =
      cols : Math.floor @screen.getWidth()/8
      rows : (Math.floor @screen.getHeight()/16)
    if not obj.rows or not obj.cols
      obj.rows = 30
      obj.cols = 120
    return obj

  getSize: ->
    @calculateSize()

class Shell_UIControls extends KDView
  constructor:(options)->
    super options
    @menu =
      type : "contextmenu"
      items : [
        { title : 'Restart terminal', id : 2,  parentId : null, function : 'reset:' },
        { title: "Close other views", id : 3,  parentId : null, function : "closeOtherSessions" }
      ]
    
    # id = 4
    # @menu.items.push title:"Restart with Anyterm.js", id:id, parentId: null, function: "reset:anyterm.js"
    # if TerminalClientFactory.getTotalRegisteredClientsCount() > 1
    #   TerminalClientFactory.forEach (clientName)=>        
    #    id++
  viewAppended: ->
    settingsButton = new KDButtonViewWithMenu
      style                   : 'editor-advanced-settings-menu'
      title                   : ''
      icon                    : yes
      delegate                : @
      iconClass               : "cog-white"
      menu                    : [@menu]
      callback                : (event)-> settingsButton.contextMenu event

    settingsButton.registerListener 
      KDEventTypes  :'ContextMenuFunction'
      listener      : @
      callback      : => 
        @getDelegate().propagateEvent (KDEventType:"AdvancedSettingsFunction"), arguments[1]

    @addSubView settingsButton


class ShellInputView extends KDInputView

  constructor:(options) ->
    super options
    window.tt = @
  stop:->
    @client = null
  setHandler:(@client)->
    @client.setHandler (data)=>
      @emit "data", data
  focus:->
    @parent.setClass "terminal-on-focus"

  blur:->
    @parent.unsetClass "terminal-on-focus"

  keyPress:(event)->
    @client?.keyPress event

  keyDown:(event)->
    @client?.keyDown event

  paste:(event)->
    setTimeout =>
      pastedContent = @getValue()
      @emit 'data', pastedContent
      @setValue ''
    , 10
