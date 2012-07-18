class AppController extends KDViewController
  initApplication:(options,callback)=>
    @openDocuments = []
    callback()
    # controller = @
    # # console.log 'init application called'
    # @applyStyleSheet ()=>
    #   bongo.api.JUser.fetchUser (err,user)->
    #     controller.setView mainView = new PreviewerView()
    #     mainView.openPath user.tenderAppLink
    #     callback?()
    #     controller.propagateEvent
    #       KDEventType : 'ApplicationInitialized', globalEvent : yes

  initAndBringToFront:(options,callback)=>
    # console.log 'initAndBringToFront'
    @initApplication options, =>
      @bringToFront()
      callback()

  bringToFront:(frontDocument)=>
    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle:yes
        name:'Beta Feedback'
      data : tempView = new KDView()
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : tempView
    # @propagateEvent
    #   KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    # ,
    #   options:
    #     hiddenHandle:yes
    #     name:'Feedback'
    #   data : @getView()
  
  applyStyleSheet:(callback)->
    requirejs ['text!KDApplications/Viewer.kdapplication/app.css'], (css)->
      $("<style type='text/css'>#{css}</style>").appendTo("head");
      callback?()

define ()->
  application = new AppController()
  {initApplication, initAndBringToFront, bringToFront} = application
  {initApplication, initAndBringToFront, bringToFront}
  #the reason I'm returning the whole instance right now is because propagateEvent includes the whole thing anyway. switch to emit/on and we can change this...
  return application


class PreviewerView extends KDCustomHTMLView
  constructor:(options = {},data)->
    options.tagName = 'iframe'
    options.cssClass = 'previewer-body'
    @clean = yes
    super options,data
    
  openPath:(path)->
    @clean = no
    @$().attr 'src', path
  
  isDocumentClean:->
    @clean