###
## Main Application controller class
###
class AppController extends KDViewController
  ###
  ##Main Application controller class
  ###
  constructor:()->
    ###
    The application controller will be instantiated when the module is loaded, before the methods are exposed to the ApplicationManager.    
    ###
    super
    
  initApplication:(options,callback)=>
    ###
    Application initialization code
    
    This is called by the ApplicationManager when it wants the application to initialize.
    When the application is finished initializing, fire the callback and propagate the event 'ApplicationInitialized'.
    This is where we can apply a style sheet for this application:
    
        @applyStyleSheet ()=>  
          callback?()  
          @propagateEvent  
            KDEventType : 'ApplicationInitialized', globalEvent : yes
    
    For a single-window application, you can instantiate the main application view here, and set it as the controller's view.
    
    To do this:
    
        @setView new AppMainView  
    
    For a single window application, you should register a listener on the mainView for the 'ViewClosed' event:
    
        mainView.registerListener KDEventTypes:'ViewClosed', listener:@, callback:@_closeView

    ###
    @applyStyleSheet ()=>
      callback()
      @propagateEvent
        KDEventType : 'ApplicationInitialized', globalEvent : yes
  
  bringToFront:()=>
    ###
    This is called by the ApplicationManager when it wants the applicatin to show it's window
    
    This is not called in the case of an application having a plugin, and that plugin being called, or in the case of view-less applications
    
    After doing whatever preparation is necessary the application should propagate the 'ApplicationWantsToBeShown' event, passing an object with options and data properties as follows:
    
        options :
          name : 'Application Name'
          type : none | 'application' | 'background'
          <tabHandleView> : new TabHandleView
          hiddenHandle : yes/no (whether the application has a visible tab handle)
        data    :
          application view to be shown by the ApplicationManager
    
    Example:
    
        @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
          options :
            name : 'Application Name'
            type : 'application'
            tabHandleView : new TabHandleView()
            hiddenHandle:no
          data : @getView()
    ###
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Terminal'
        type : 'application'
        tabHandleView : new TabHandleView()
        hiddenHandle:no
      data : @getView()
      
    @getView().input.setFocus()
    
  initAndBringToFront:(options,callback)=>
    ###
    Called when the application wants to bringToFront an application that hasn't yet been initialized. Default contents:
    
        @initApplication options, =>
          @bringToFront()
          callback()
    ###
    @initApplication options, =>
      @bringToFront()
      callback()
  
  setEnvironment:(@environment)->
  getEnvironment:->@environment
  
  _closeView:(view)->
    ###
    ##\##(an example internal method in an application)
    To close the application window, propagate the event 'ApplicationWantsToClose' with the main view in the data property:
    
        @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : view
    ###
    @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : view
  
  applyStyleSheet:(callback)->
    ###
    This is an example of applying your own styles to the application:
    
        requirejs ["text!KDApplications/Shell.kdapplication/app.css?#{KD.version}"], (css)->
          $("<style type='text/css'>#{css}</style>").appendTo("head");
          callback?()
    ###
    requirejs ["text!KDApplications/Shell.kdapplication/app.css?#{KD.version}"], (css)->
      $("<style type='text/css'>#{css}</style>").appendTo("head");
      callback?()
  
  
  
  loadView:(mainView)->
    ###
    Will be called when the application view is appended.
    ###


class TabHandleView extends KDView
  ###
  ## TabHandleView (optional) ##
  You can optionally pass an instance of this class with the options of the "ApplicationWantsToBeShown" event
  ###
  setDomElement:()->
    ###
    Example of customizing the tab view
    ###
    @domElement = $ "<b>AppName</b>
      <span class='kdcustomhtml appClass icon'></span>
      <span class='close-tab'></span>"

###
# Application Exports #
###
define ()->
  application = new AppController()
  {initApplication, initAndBringToFront, bringToFront, openFile} = application
  {initApplication, initAndBringToFront, bringToFront, openFile}
  #the reason I'm returning the whole instance right now is because propagateEvent includes the whole thing anyway. switch to emit/on and we can change this...
  return application