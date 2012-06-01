class Register12345 extends AppController

  constructor:()->
    mainViewClass = KDView
    mainViewClass = KD.getPageClass('Register') if KD.getPageClass('Register')?

    @mainView = new mainViewClass {cssClass : "content-page" }
    super
  
  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Register'
      data : @mainView
    
  initAndBringToFront:(options, callback)->
    @bringToFront()
    callback()
