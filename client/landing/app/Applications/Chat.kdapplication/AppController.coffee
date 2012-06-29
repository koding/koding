# class Chat12345 extends AppController
#   constructor:()->
#     mainViewClass = KDView
#     mainViewClass = KD.getPageClass('Activity') if KD.getPageClass('Activity')?
# 
#     @mainView = new mainViewClass {cssClass : "content-page" }
#     super
#   
#   bringToFront:()->
#     @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes), options : {}, data : @mainView
#     
#   initAndBringToFront:(options,callback)->
#     @bringToFront()
#     callback()

class ChatRoom


  constructor:(options,callback)->
    
  
  fetchRoom :({id},callback)->
        

    

class @Chatter
  {mq} = bongo
  
  constructor:()->

  
  joinRoom:(options,callback)->
    
    {id,callbacks} = options
    

    @name = "private-chat-#{__utils.getRandomNumber}"
    @room = mq.channel(@name)
    
    if @room?
      callback @room
    else
      mq.subscribe(@name)
      @room.bind 'pusher:subscription_succeeded', ->
        console.log('success', arguments)
        callback null,@room


        room.bind 'client-chat-msg',->
          console.log arguments
    
    
  sendMsg : (options,callback)->
    {msg} = options
    @room.trigger 'client-chat-msg',msg
    
    
      