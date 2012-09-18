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
      # console.log 'newScreen',scr
      @sharedDoc.send {newScreen:screen}

    view.on 'userWantsToJoin',=>
      console.log 'user joined'
      @sharedDoc.join {name:"myDoc"}

    view.on 'cursorPositionChanged',(cursorPosition)=>
      log "cursorPosition",cursorPosition
      @cursorPosition = cursorPosition

  bringToFront:()->
    super name : 'Chat'#, type : 'background'









