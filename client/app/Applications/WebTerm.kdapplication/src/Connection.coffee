class WebTerm.Connection
  constructor: (@terminal) ->
    @ws = new WebSocket("ws://" + window.location.hostname + ":8080/")
    $(window).bind "beforeunload", =>
      @ws.close()
    
    @startupQueue = []
    @controlCodeReader = WebTerm.createAnsiControlCodeReader(@terminal)
    dnode = WebTerm.newDNode
      sessionStarted: () =>
        @terminal.inSession = true
        @terminal.scrollToBottom()
        @terminal.cursor.resetBlink()
      
      sessionEnded: () =>
        @terminal.inSession = false
        @showSessions()
      
      output: (data) =>
        console.log @terminal.inspectString(data) if localStorage?["WebTerm.logRawOutput"] is "true"
        @controlCodeReader.addData data
        if localStorage?["WebTerm.slowDrawing"] is "true"
          @controlCodeInterval ?= window.setInterval =>
            atEnd = @controlCodeReader.process()
            if localStorage?["WebTerm.slowDrawing"] isnt "true"
              atEnd = @controlCodeReader.process() until atEnd
            @terminal.screenBuffer.flush()
            if atEnd
              window.clearInterval @controlCodeInterval
              @controlCodeInterval = null
          , 20
        else
          atEnd = false
          atEnd = @controlCodeReader.process() until atEnd
          @terminal.screenBuffer.flush()
    
    dnode.on "remote", (remote) =>
      @terminal.server = remote
    
    dnode.on "ready", =>
      @showSessions()
    
    dnode.on "data", (data) =>
      if @startupQueue
        @startupQueue.push data
      else
        @ws.send data
    
    @ws.onopen = (event) =>
      while @startupQueue.length > 0
        @ws.send @startupQueue.shift()
      @startupQueue = null
      
    @ws.onclose = (event) =>
      @terminal.inSession = false
      @terminal.resetStyle()
      @terminal.setStyle "textColor", 1
      @terminal.lineFeed()
      @terminal.lineFeed()
      @terminal.cursor.moveTo 0, @terminal.cursor.y
      @terminal.writeText "Connection closed."
      @terminal.cursor.setVisibility false
      @terminal.screenBuffer.flush()
      @terminal.scrollToBottom()
    
    @ws.onmessage = (event) =>
      dnode.write event.data
  
  showSessions: ->
    @terminal.server.getSessions (sessions) =>
      @terminal.showSessionsCallback sessions
