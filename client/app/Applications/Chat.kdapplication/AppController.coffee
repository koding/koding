class @Chatter extends KDEventEmitter
  {mq} = bongo
  
  constructor:()->
    @account = KD.whoami()
    @username = @account.profile.nickname
  
  
  newJoinRoom:->
    
    mq.fetchChannel "private-chat-12345",(channel,isNew)=>
      
      @room = channel
      
      channel.on "client-chat-msg",->
        bla()
  
  joinRoom:(options,callback)->
    
    {name,type,callbacks} = options
    
    name ?= __utils.getRandomNumber
    type ?= "chat"
    @name = "private-#{type}-#{name}"
    # @room = mq.channel(@name)
    # console.log "creating room with #{@name}"
    # if @room?
    #   callback null,{room:@room,name:@name,isNew:yes}
    # else
    #   @room = mq.subscribe(@name)
    #   @room.bind 'pusher:subscription_succeeded', =>
    #     console.log('success', arguments)
    #     callback null,{room:@room,name:@name,isNew:yes}
      @room.bind 'client-#{type}-msg',callbacks.data
        
  sendMsg : ({msg},callback) -> 
    @room.emit 'client-chat-msg',{msg,username:@username,date:Date.now()}



class @SharedDoc extends @Chatter
  
  
  constructor:(options)->
    {isMaster} = options
    @isMaster = isMaster
    @lastScreen = ""
    super
    
  
  join :(options,callback)->
    
    @joinRoom type:"sharedDoc",callbacks: data: @msgDidArrive,(err,res)->
      
  
  @msgDidArrive: ({msg,username,date})->
    @currentScreen = @dmp.patch_apply msg,@lastScreen
    @emit "screenDidChange",@currentScreen
  
  @sendMsg :->
    msg = msg apply diff
    super arguments
    
    
      