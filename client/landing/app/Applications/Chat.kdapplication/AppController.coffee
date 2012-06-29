



class Chatter extends KDEventEmitter
  {mq} = bongo
  
  constructor:()->
    @account = KD.whoami()
    @username = @account?.profile?.nickname ? "guest"
    @type = "chat"
    @messages = []
    super
  joinRoom:(options,callback)->
    
    {name} = options
    
    name ?= __utils.getRandomNumber()
    @name = "private-#{@type}-#{name}"
    mq.fetchChannel @name,(channel,isNew)=>
      console.log arguments
      if isNew is yes
        console.log @username+" created a channel: #{@name}"
      else
        console.log @username+" joined this channel: #{@name}"      
      
      @room = channel      
      @emit "ready",isNew
      @attachListeners(isNew)
      
  attachListeners:(isNew)->
    @room.on 'client-#{@type}-msg',(messages)=>
      for msgObj in messages
        @emit "msg",msgObj
      
  sendThrottled : _.throttle ()->
    @room.emit 'client-#{@type}-msg',@messages
    @messages = []
  ,150
  
  send : ({msg},callback) ->
    msgObj = {msg,date:Date.now(),sender:@username}
    @messages.push msgObj
    @sendThrottled()




class SharedDoc extends Chatter  
  
  constructor:(options)->
    # {isMaster} = options
    # @isMaster = isMaster ? null
    @lastScreen = ""
    super
    @type = "sharedDoc"
    @dmp = new diff_match_patch()
    
  attachListeners:(isNew)->
    super isNew
    #console.log "attachlisteners cagirdik"
    @on "ready",(isNew)=>
      #@isMaster = yes if isNew

    @on "msg",({msg,sender,date})=>
      # if sender isnt @username  
      # console.log "sharedDoc geldi",arguments 
      @currentScreen = (@dmp.patch_apply msg,@lastScreen)[0]
      @lastScreen = @currentScreen
      @emit "patchApplied",@currentScreen
        
      
  join :(options,callback)->    
    @joinRoom options,(err,res)->
  
  send : ({newScreen},callback)->
    patch = @dmp.patch_make @lastScreen, newScreen   
    @lastScreen = newScreen
    # console.log newScreen,patch
    super msg:patch   
      

class ChatterView extends KDView
  
  viewAppended:->
    @addSubView @joinButton = new KDButtonView
      title    : "Share"
      callback : =>
        @emit "userWantsToJoin"
    
    @addSubView @input = new KDInputView
      type    : "textarea"      
      keyup   : =>
        @emit 'newScreen',@input.getValue()

      paste   : =>
        @emit 'newScreen',@input.getValue()        

    
    @input.setHeight @getSingleton("windowController").winHeight-100
    @input.setWidth  @getSingleton("windowController").winWidth-200
    
class Chat12345 extends AppController
  
  constructor:(options = {}, data)->
    options.view = new ChatterView
      cssClass : "content-page chat"

    super options, data
    view = @getView()
    @sharedDoc = new SharedDoc
    
    @sharedDoc.on "patchApplied",(newScreen)=>
      view.input.setValue newScreen
    

    
  loadView:(view)->

    view.on 'newScreen',(scr)=>
      @sharedDoc.send {newScreen:scr}
    
    view.on 'userWantsToJoin',=>
      @sharedDoc.join {name:"myDoc"}
    
  bringToFront:()->
    super name : 'Chat'#, type : 'background'
      
      
      
      
      
      
      
      
      
      