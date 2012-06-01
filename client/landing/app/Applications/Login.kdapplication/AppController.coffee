class Login12345 extends AppController
  constructor:()->
    options.view =  @mainView = new LoginScreen {cssClass : "content-page login" }
    super
  
  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Login'
      data : @mainView
    
  initAndBringToFront:(options, callback)->
    @bringToFront()
    callback()