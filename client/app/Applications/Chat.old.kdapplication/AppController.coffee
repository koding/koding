class KDChannel extends KDEventEmitter
  {mq} = bongo

  constructor:()->
    @account = KD.whoami()
    @username = @account?.profile?.nickname
    @username = "Guest"+__utils.getRandomNumber() if @username is "Guest"
    @type = "base"
    @messages = []
    @participants = {}
    @state = {}
    @master = null
    super

  joinRoom:(options,callback)->

    {name} = options

    name ?= __utils.getRandomNumber()
    @name = "private-#{@type}-#{name}"
    mq.fetchChannel @name,(channel,isNew)=>
      log arguments
      log @username+" joined this channel: #{@name}"

      @room = channel
      @emit "ready"
      @attachListeners()
      @send event:"join"

      setTimeout =>
        {master,nrOfParticipants} = @getRoomInfo()
        if nrOfParticipants is 0
          log "seems like nobody is in this room. You're now the master host.",@participants
          @isMaster = yes
        else
          log "There are #{nrOfParticipants} people in this room.",@participants
          @send event:"getScreen",recipient:master
      ,1000

  getRoomInfo:->
    i=0
    for username,participant of @participants
      master = username if participant.isMaster is yes
      i++
    @master = master
    return master:master,nrOfParticipants:i

  attachListeners:()->
    @room.on 'client-#{@type}-msg',(messages)=>
      for msgObj in messages
        {event,recipient} = msgObj
        if recipient
          @emit "#{event}-#{recipient}",msgObj
        else
          @emit event,msgObj



  sendThrottled : _.throttle ->
    if @room
      @room.emit 'client-#{@type}-msg',@messages
      @messages = []
      clearInterval @state.joiningIsInProgress if @state.joiningIsInProgress
    else
      unless @state.joiningIsInProgress
        log "@room is not ready yet, will keep on trying every sec."
        @state.joiningIsInProgress = setInterval ->
          log "trying to join to the @room"
          @sendThrottled()
        ,1000
  ,110


  send : (options,callback) ->
    # log "finally sending:",options
    options.date = Date.now()
    options.sender = @username
    options.event ?= "msg"
    @messages.push options
    @sendThrottled()

class Chat extends KDChannel

  constructor:->
    super
    @msgHistory = []
    @type = "chat"
  attachListeners:->


class SharedDoc extends KDChannel

  constructor:(options)->
    # {isMaster} = options
    # @isMaster = isMaster ? null
    @lastScreen = ""
    super
    @type = "sharedDoc"
    @dmp = new diff_match_patch()

  attachListeners:->
    super
    #log "attachlisteners cagirdik"
    @on "ready",(isNew)=>
      #@isMaster = yes if isNew

    @on "patch",({patch,sender,date})=>
      # if sender isnt @username
      # log "sharedDoc on.patch geldi",arguments
      @registerAndEmitScreen patch,sender,date

    @on "join",({sender,date})=>
      log "#{sender} geldi hosgeldi",arguments
      # make this  efficient later.
      # if @isMaster
      @send event:"ping",screen:@lastScreen #,isMaster:@isMaster
      # else
      #   @send event:"ping"

    @on "ping",({sender,screen,isMaster})=>
      log "#{sender} said 'hi'.",arguments,@master
      @participants[sender] = status:"online",lastPing:Date.now(),isMaster:isMaster
      # if screen and sender is @master
      if screen
        @lastScreen = screen
        @emit "screen",screen

    @on "getScreen-#{@username}",({sender})=>
      log "#{sender} wanted to get the latest screen from me. sending.."
      @send event:"screen",screen:@lastScreen,recipient:sender

    @on "screen-#{@username}",({screen,sender})->
      log "i got screen from #{sender}"
      @lastScreen = screen
      @emit "screen",screen

  registerAndEmitScreen:({patch})->
    sha1 = SHA1.hex_sha1 @lastScreen
    if @screens[sha1]?
      # nothing changed on screen, no need to emit.
    else
      (@screens[sha1] ?= []).push {patch,sender}

      @currentScreen = (@dmp.patch_apply patch,@lastScreen)[0]
      @lastScreen = @currentScreen
      @emit "patchApplied",@currentScreen,sender


  join :(options,callback)->
    @joinRoom options,(err,res)->

  send : (options,callback)->
    # log 'zz',arguments
    {newScreen,event} = options
    if newScreen
      patch = @dmp.patch_make @lastScreen, newScreen
      @lastScreen = newScreen
      super event:"patch",patch:patch
    else
      # log "sending",options
      super options








class ChatterView extends KDView

  viewAppended:->
    # @addSubView @joinButton = new KDButtonView
    #   title    : "Share"
    #   callback : =>
    #
    file = FSHelper.createFileFromPath "localfile:/Untitled#{postfix}.txt"
    @addSubView @ace = new Ace {},file
    window.A = @ace
      # type    : "textarea"
      # keyup   : =>
      #   @emit 'newScreen',@input.getValue()
      #
      # paste   : =>
      #   @emit 'newScreen',@input.getValue()
    @ace.on "ace.ready",=>
      @emit "userWantsToJoin"

      @ace.editor.getSession().on "onTextInput",(e)->
        log "onTextInput",e

      @ace.editor.getSession().on "onDocumentChange",(e)->
        log "onDocumentChange",e

      @ace.editor.getSession().on "change",(e)=>
        # log "e",e
        {row,column}  = e.data.range.end
        cursorPosition  = {row,column}
        # @ace.setContents "abc"
        @emit 'cursorPositionChanged',cursorPosition
        # @emit 'newScreen',{screen:@ace.getContents(),event}

    # @input.setHeight @getSingleton("windowController").winHeight-100
    # @input.setWidth  @getSingleton("windowController").winWidth-500

  click : ->
    @setKeyView()

  keyUp:(event) ->
    # log "SHA1-hex",SHA1.hex_sha1 @ace.getContents()
    # log "SHA1-b64",SHA1.b64_sha1 @ace.getContents()
    # log "SHA1-any",SHA1.any_sha1 @ace.getContents()


    @emit 'newScreen',{screen:@ace.getContents()}

  keyDown: ->
    # log "down",arguments

class Chat12345 extends AppController

  constructor:(options = {}, data)->
    options.view = new ChatterView
      #cssClass : "content-page chat"
    @cursorPosition = {}

    super options, data
    @view = @getView()
    @sharedDoc = new SharedDoc

    @sharedDoc.on "patchApplied",(newScreen,sender)=>
      # view.input.setValue newScreen
      log "#{sender} sent a new patch."
      @setScreen newScreen

    @sharedDoc.on "screen",(newScreen)=>
      # view.input.setValue newScreen
      @setScreen newScreen

  setScreen:(newScreen)->
    {row,column}  = @cursorPosition
    @view.ace.setContents newScreen
    @view.ace.editor.getSession().getSelection().selectionLead.setPosition row,column


  loadView:(view)->

    view.on 'newScreen',({screen})=>
      # log 'newScreen',scr
      @sharedDoc.send {newScreen:screen}

    view.on 'userWantsToJoin',=>
      log 'user joined'
      @sharedDoc.join {name:"myDoc"}

    view.on 'cursorPositionChanged',(cursorPosition)=>
      log "cursorPosition",cursorPosition
      @cursorPosition = cursorPosition

  bringToFront:()->
    super name : 'Chat'#, type : 'background'









