class TabHandleView extends KDView
  setDomElement:()->
    @domElement = $ "<b>Terminal</b>
      <span class='kdcustomhtml terminal icon'></span>"

class Mio extends KDView
  # setDomElement :->
  #   @domElement = $ <div id="termDiv" style="position:absolute; visibility: hidden; z-index:1;"></div>

class Shell12345 extends AppController

  constructor:(options = {}, data)->
    options.view = new Mio
      cssClass : "content-page mio"
      domId    : "termDiv"
      
    super options, data

  bringToFront:()->
    super name : 'Mio'#, type : 'background'

  loadView:(mainView)->
    log mainView
    # mainView.setPartial '<div id="termDiv" style="position:absolute; visibility: hidden; z-index:1;"></div>'
    @view = mainView
    #@view.setDomId "Terminal"+Date.now()
    #log @view.getDomId()
    @termOpen()

  termOpen : ->
    termGlobDict =
      a: [ "all", "alternate", "any", "anyone", "anywhere", "anyhow", "are", "arbitrage", "arbitrary" ]
      b: [ "bar", "bit", "byte", "better", "best", "boost", "booster" ]
      c: [ "case", "character", "completion" ]
      d: [ "delete", "dialog", "display" ]
      e: [ "either", "element", "empty" ]
      f: [ "first", "foo", "function" ]
      g: [ "get", "glob", "globbing" ]
      h: [ "head", "heat", "help" ]
      i: [ "is", "it", "iteration" ]
      j: [ "joke", "just", "justice" ]
      k: [ "karma", "kilo", "kilobit" ]
      l: [ "lambda", "like", "limit" ]
      m: [ "meta", "metaphysic", "metaphor" ]
      n: [ "neither", "never", "number" ]
      o: [ "object", "open", "order" ]
      p: [ "parser", "print", "prompt" ]
      q: [ "quantum", "query", "quote" ]
      r: [ "remember", "rest", "roman" ]
      s: [ "sane", "some", "sort" ]
      t: [ "target", "tell", "tolerance" ]
      u: [ "under", "upper", "urgent" ]
      v: [ "vane", "vertical", "vital" ]
      w: [ "want", "which", "width" ]
      x: [ "x-ray", "xanadu", "xylophone" ]
      y: [ "yacht", "yet", "ypsilon" ]
      z: [ "zet", "zeta", "zoom" ]
      nonalpha: [ "100", "1000", "0.0", "#!/usr/bin/perl" ]
      
    termExitHandler = ->
      mainPane = (if (document.getElementById) then document.getElementById("mainPane") else document.all.mainPane)
      mainPane.className = "lh15"  if mainPane
    termHandler = ->
      @newLine()
      if @lineBuffer.search(/^\s*exit\s*$/i) is 0
        @close()
        return
      else unless @lineBuffer is ""
        @type "You typed: " + @lineBuffer
        @newLine()
      @prompt()

    termCtrlHandler = ->
      ch = @inputChar
      if ch is termKey.TAB or ch is termKey.ESC
        @lock = true
        line = @_getLine()
        words = line.split(/\s+/)
        if words.length
          word = words[words.length - 1]
          if word
            found = new Array()
            dialog = undefined
            re = undefined
            qword = undefined
            rword = undefined
            i = undefined
            @env.globBuffer = new Array()
            firstletter = word.charAt(0).toLowerCase()
            firstletter = "nonalpha"  if firstletter < "a" or firstletter > "z"
            dict = termGlobDict[firstletter]
            if dict
              qword = word.replace(/([\\\/\+\-\.\*\?\[\]\{\}\(\)^$\|\!])/g, "\\$1")
              re = new RegExp("^" + qword, "i")
              rword = new RegExp("^" + qword + "$", "i")
              i = 0
              while i < dict.length
                found.push dict[i]  if re.test(dict[i]) and not rword.test(dict[i])
                i++
            if found.length
              found.length = 9  if found.length > 9
              found.sort()  if termGlobSortAlphabetical
              dialog = new Array()
              dialog.push "Suggestions for \"" + word + "\":"
              dialog.push ""
              dialog.push "  0  " + word + " (CANCEL)"
              i = 0
              while i < found.length
                dialog.push "  " + (i + 1) + "  " + found[i]
                @env.globBuffer[i] = String(found[i]).replace(re, "")
                i++
              dialog.push ""
              dialog.push ""
              dialog.push "Choose an option or press any key to continue."
              @env.globCursor = 0
            else
              dialog = [ "No suggestions found for \"" + word + "\".", "", "", "Press any key to continue." ]
              @env.globCursor = -1
            @backupScreen()
            @maxCols = @conf.cols
            @maxLines = @conf.rows
            termGlobbingShowDialog this, dialog
            termGlobbingSetDialogCursor this, 0  if found.length
            @charMode = true
            @handler = @ctrlHandler = termGlobbingHandler
        @lock = false
      else
        return
    termGlobbingHandler = ->
      ch = @inputChar
      if @env.globCursor >= 0
        if ch is termKey.UP
          termGlobbingSetDialogCursor this, -1  if @env.globCursor > 0
          return
        if ch is termKey.DOWN
          termGlobbingSetDialogCursor this, 1  if @env.globCursor < @env.globBuffer.length
          return
      @restoreScreen()
      completion = undefined
      if ch >= 49 and ch <= 48 + @env.globBuffer.length
        completion = @env.globBuffer[ch - 49]
      else completion = @env.globBuffer[@env.globCursor - 1]  if ch is termKey.CR and @env.globCursor > 0
      if completion
        pos = @_getLineEnd(@r, @c)
        r = pos[0]
        c = pos[1]
        if ++c is @maxCols
          c = 0
          r++
        @cursorOff()
        @cursorSet r, c  if @r isnt r or @c isnt c
        @type completion
        @cursorOn()
      @env.globBuffer.length = 0
      @env.globCursor = -1
      @lock = false
    termGlobbingShowDialog = (termRef, lines) ->
      horizontalMargin = 5
      verticalMargin = 2
      horizontalBorderChar = "-"
      verticalBorderChar = "|"
      cornerChar = "+"
      style = 8 * 256
      l = termRef.conf.cols - horizontalMargin - 1
      i = undefined
      n = undefined
      line = undefined
      b0 = cornerChar
      b1 = verticalBorderChar
      b2 = verticalBorderChar + "  "
      b3 = " " + verticalBorderChar
      i = horizontalMargin + b0.length
      while i < l
        b0 += horizontalBorderChar
        i++
      i = horizontalMargin + b1.length
      while i < l
        b1 += " "
        i++
      b0 += cornerChar
      b1 += verticalBorderChar
      l2 = l - b3.length - horizontalMargin
      r = verticalMargin
      termRef.typeAt r++, horizontalMargin, b0, style
      termRef.typeAt r++, horizontalMargin, b1, style
      n = 0
      while n < lines.length
        unless lines[n] is ""
          line = b2 + lines[n]
          i = line.length
          while i <= l2
            line += " "
            i++
          termRef.typeAt r++, horizontalMargin, line + b3, style
        else
          termRef.typeAt r++, horizontalMargin, b1, style
        n++
      termRef.typeAt r++, horizontalMargin, b1, style
      termRef.typeAt r, horizontalMargin, b0, style
    termGlobbingSetDialogCursor = (termRef, motion) ->
      horizontalMargin = 5
      verticalMargin = 2
      r = undefined
      sr = undefined
      i = undefined
      c = horizontalMargin + 4
      motion = 0  unless motion
      if termRef.env.globCursor >= 0 and motion
        r = verticalMargin + 4 + termRef.env.globCursor
        sr = termRef.styleBuf[r]
        i = c
        while i < c + 3
          sr[i] &= 0xfffffffe
          i++
        termRef.redraw r
      termRef.env.globCursor += motion
      r = verticalMargin + 4 + termRef.env.globCursor
      sr = termRef.styleBuf[r]
      i = c
      while i < c + 3
        sr[i] |= 1
        i++
      termRef.redraw r


    if (not term) or (term.closed)
      term = new Terminal
        x: 0 # @view.getWidth()  #220
        y: 0 # @view.getHeight() #70
        rows : @getView().getHeight()/16
        cols : @getView().getWidth()/6
        termDiv: @getView().getDomId()
        bgColor: "#232e45"
        greeting: "%+r **** termlib.js globbing sample **** %-r%n%ntype any text and hit ESC or TAB for globbing.%ntype \"exit\" to quit.%n "
        # handler: termHandler
        exitHandler: termExitHandler
        # ctrlHandler: termCtrlHandler
        printTab: false
        closeOnESC: false
  
      term.open()
      mainPane = (if (document.getElementById) then document.getElementById("mainPane") else document.all.mainPane)
      # mainPane = document.getElementById @view.getDomId
      mainPane.className = "lh15 dimmed"  if mainPane
      window.TT = term


























class Shell123456 extends KDViewController

  constructor:()->
    super
    @account = KD.whoami()
    # @getKiteIds kiteName:"terminaljs",->
    @_terminalId = null
    @setView shellView = new Mio
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
        currentScreen = (@dmp.patch_apply diff,@lastScreen)[0]
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
    @account.fetchKiteIds {kiteName:"terminaljs"},(err,kiteIds)->
      unless err
        @kiteIds = kiteIds
        callback? null,kiteIds
      else
        callback? err

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
      mainView.registerListener
        KDEventTypes : "resize"
        listener     : @
        callback     : @resizeTerminal
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
  ,250
  
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

