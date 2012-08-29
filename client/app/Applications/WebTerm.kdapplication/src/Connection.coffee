class WebTerm.Connection
  constructor: (@terminal) ->
    @controlCodeReader = WebTerm.createAnsiControlCodeReader(@terminal)
    
    KD.whoami().tellKite
      kiteName: 'webterm',
      method: 'createServer',
      withArgs:
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
    , (remote) =>
      @terminal.server = remote
      @showSessions()
  
  showSessions: ->
    @terminal.server.getSessions (sessions) =>
      @terminal.showSessionsCallback sessions
