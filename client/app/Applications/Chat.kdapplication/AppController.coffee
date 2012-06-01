class Chat12345 extends AppController
  constructor:()->
    mainViewClass = KDView
    mainViewClass = KD.getPageClass('Activity') if KD.getPageClass('Activity')?

    @mainView = new mainViewClass {cssClass : "content-page" }
    super
  
  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes), options : {}, data : @mainView
    
  initAndBringToFront:(options,callback)->
    @bringToFront()
    callback()