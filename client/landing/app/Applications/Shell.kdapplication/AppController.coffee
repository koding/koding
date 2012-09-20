class TabHandleView extends KDView

  setDomElement:()-> @domElement = $ "<b>Terminal</b><span class='kdcustomhtml terminal icon'></span>"

class Shell12345 extends KDViewController

  constructor:()->
    super
    @account = KD.whoami()
    # @getKiteIds kiteName:"terminaljs",->
    @_terminalId = null
    @setView shellView = new ShellView
    @resetMessageCounter()
    shellView.registerListener KDEventTypes:'ViewClosed', listener:@, callback:@closeView
    resetRegexp = /reset\:.*?/
    @dmp = new diff_match_patch()
    @lastScreen = ""
    @sendCount = 0
    @keyStrokeCount = 0
    @resetBufferedKeyStrokes()

    shellView.registerListener KDEventTypes:'AdvancedSettingsFunction', listener:@, callback:(pubInst, {functionName})=>
      switch functionName
        when 'clear'
          @send "clear\n"
        when 'closeOtherSessions'
          try
            @terminal.closeOtherSessions()
          catch e
            console.log "terminal:closeOtherSessions error : #{e}"
        else
          if resetRegexp.test functionName
            clientType = functionName.substr 6
            if not clientType
              clientType = shellView.clientType
            @resetTerminalSession clientType


  nextScreenDiff:(data, messageNum)->
    {_lastMessageProcessed, _orderedMessages} = @
    _orderedMessages[messageNum] = data
    if messageNum is _lastMessageProcessed
      doThese = []
      i = _lastMessageProcessed
      for diff in (item while (item = _orderedMessages[i++])?)
        # console.log "updating screen with:",diff
        patch = (@dmp.patch_fromText diff)
        currentScreen = (@dmp.patch_apply patch,@lastScreen)[0]
        # currentScreen = diff
        @getView().updateScreen(currentScreen)
        @lastScreen = currentScreen
        @_lastMessageProcessed = i-1

  resetMessageCounter:->
    console.log 'message counter is reset.'
    @_lastMessageProcessed = 0
    @_orderedMessages = []

  generateTerminalOptions : ()->
    view = @getView()
    options = view.getSize()
    options.callbacks =
      data : (data, messageNum) =>
        @nextScreenDiff data, messageNum

        # console.log "screen:",JSON.stringify data,messageNum
      error : (error) =>
        @getView().disableInput()
        msg = "connection closed"
        if error.msg then msg += ",#{error.msg}"
        @setNotification msg

      ping : () =>
        try
          @terminal.ping()
        catch e
          console.log "terminal ping error: #{e}"

    options.callbacks.newSession = (totalViews)=>
      console.log "new session"
      notification = new KDNotificationView
        title   : "Terminal has #{totalViews} views"
        duration: 1500
    return options


  setNotification:(msg)->
    if @notification?
      @notification.destroy()
      delete @notification
    if msg?
      @notification = new KDNotificationView
        title   : "#{msg}"
        duration: 0
        click   : =>
          @notification.destroy()

  resetTerminalSession :(type)->
    @setNotification "restarting terminal"
    view = @getView()
    view.reset type
    try
      @terminal.kill()
      @resetMessageCounter()
    catch e
      console.log "terminal kill error : #{e}"
    options = @generateTerminalOptions()
    options.type = type ? view.clientType
    @account.tellKite
      kiteName :"terminaljs"
      toDo     :"create"
      withArgs : options
    ,(error,terminal)=>
      if error
        @setNotification "Failed to start terminal : #{error}"
      else
        @setNotification()
        @terminal = terminal
        @welcomeUser yes

  initApplication:(options,callback)=>
    @applyStyleSheet ()=>
      callback()
      @propagateEvent
        KDEventType : 'ApplicationInitialized', globalEvent : yes

  bringToFront:()=>
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name              : 'Terminal'
        type              : 'application'
        tabHandleView     : new TabHandleView()
        hiddenHandle      : no
        applicationType   : 'Shell.kdapplication'
      data : @getView()

    appManager.addOpenTab @getView(), 'Shell.kdapplication'
    @getView().input.setFocus()

  initAndBringToFront:(options,callback)=>
    @initApplication options, =>
      @bringToFront()
      callback()

  closeView:(view)->
    appManager.removeOpenTab @getView()
    view.parent.removeSubView view
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : view
    view.destroy()
    @setNotification()
    try
      @terminal.kill()
    catch e
      console.log "terminal::close error #{e}"
    @resetMessageCounter()

  applyStyleSheet:(callback)->
    callback?()
    # $.ajax
    #   dataType:'text'
    #   url:"#{KD.staticFilesBaseUrl}/js/KDApplications/Shell.kdapplication/app.css?#{KD.version}"
    #   success: (css)->
    #     $("<style type='text/css'>#{css}</style>").appendTo("head");
    #     callback?()

  getKiteIds : (options,callback)->
#    @account.fetchKiteIds {kiteName:"terminaljs"},(err,kiteIds)->
#      unless err
#        @kiteIds = kiteIds
#        callback? null,kiteIds
#      else
#        callback? err

  initiateTerminal : (callback)->
    view = @getView()
    options = @generateTerminalOptions()
    options.type = view.clientType
    # @pickAResponsiveKite {},(err,kiteId)=>
    #   console.log "whatup",err,kiteId
    console.log 'initial terminal is called'
    KD.singletons.kiteController.run
      kiteName  : "terminaljs"
      # kiteId    : kiteId
      toDo      : "create"
      withArgs  : options
    , (error, terminal) =>
      if error
        @setNotification "Failed to start terminal, please close the tab and try again."
        console.log error
      else
        window.T = terminal
        @sendCount = 0
        @keyStrokeCount = 0
        @terminal = terminal
        @welcomeUser terminal.isNew
        callback? terminal.totalSessions


  loadView:(mainView)->

    @initiateTerminal (totalSessions)=>

      mainView.on "ViewResized", => @resizeTerminal

      mainView.input.on "data",(cmd)=>
        @send cmd

  welcomeUser:(isTerminalNew)->
    if isTerminalNew
      username = KD.getSingleton('mainController').getVisitor().currentDelegate.profile.nickname
      welcomeText = "cowsay mooOOooOOoo what up #{username}! welcome to your terminal... check my w"
      @send "#{welcomeText}\n"

  resizeTerminal:()->
    options     = @getView().getSize()
    try
      @terminal.resize options.rows, options.cols
    catch e
      console.log "terminal.resize error #{e}"

  sendThrottled : _.throttle ->
    @sendCount++
    baseTime = @bufferedKeyStrokes[0][2]
    k[2] = k[2] - baseTime  for k in @bufferedKeyStrokes
    @terminal.write @bufferedKeyStrokes
    console.log "#{@bufferedKeyStrokes.length} @bufferedKeyStrokes sent at - interval 500msec",new Date if @terminal.log
    @resetBufferedKeyStrokes()
  ,100

  resetBufferedKeyStrokes : -> @bufferedKeyStrokes = []

  send: (command) ->
    # console.log "sending:"+command
    delay = Date.now() #-@bufferedKeyStrokes[@bufferedKeyStrokes.length-1][1]
    @bufferedKeyStrokes.push [@keyStrokeCount,@sendCount,delay,command]
    @keyStrokeCount++
    @sendThrottled()
    # @terminal.write command

    # try
    # snd command
    # catch e
      # console.log "terminal.write error : #{e}"


# define ()->
#   application = new AppController()
#   {initApplication, initAndBringToFront, bringToFront, openFile} = application
#   {initApplication, initAndBringToFront, bringToFront, openFile}
#   #the reason I'm returning the whole instance right now is because propagateEvent includes the whole thing anyway. switch to emit/on and we can change this...
#   return application

# class Shell1234512345 extends AppController
#
#   constructor:(options = {}, data)->
#     options.view = new KDView
#       cssClass : "content-page"
#       domId    : "termDiv"
#
#     super options, data
#
#   bringToFront:()=>
#     @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
#       options :
#         name              : 'Terminal'
#         type              : 'application'
#         tabHandleView     : new TabHandleView()
#         hiddenHandle      : no
#         applicationType   : 'Shell.kdapplication'
#       data : @getView()
#
#     appManager.addOpenTab @getView(), 'Shell.kdapplication'
#     @getView().input.setFocus()
#
#   loadView:(mainView)->
#
#     @termOpen()
#
#   termOpen : ->
#
#     @term = new Terminal
#       x         : 0 # @view.getWidth()  #220
#       y         : 0 # @view.getHeight() #70
#       rows      : @getView().getHeight()/16
#       cols      : @getView().getWidth()/7
#       termDiv   : @getView().getDomId()
#       bgColor   : "#232e45"
#       greeting  : "%+r **** termlib.js globbing sample **** %-r%n%ntype any text and hit ESC or TAB for globbing.%ntype \"exit\" to quit.%n "
#       # handler: termHandler
#       # exitHandler: termExitHandler
#       # ctrlHandler: termCtrlHandler
#       # printTab: false
#       # closeOnESC: false
#
#     @term.open()
#     # mainPane = (if (document.getElementById) then document.getElementById("mainPane") else document.all.mainPane)
#     # # mainPane = document.getElementById @view.getDomId
#     # mainPane.className = "lh15 dimmed"  if mainPane
#     # window.TT = term
