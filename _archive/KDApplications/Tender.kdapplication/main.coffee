
class BasicEmitter
  constructor: ->
    @_events = {}
    
  on: (eventType, callback) ->
    unless @_events[eventType]
      @_events[eventType] = []
      
    @_events[eventType].push callback
    
  emit: (eventType, args...) ->
    return unless @_events[eventType]
    for event in @_events[eventType]
      event.apply @, args

# KD Global
@KD = do ->
  # private member for tracking z-indexes
  zIndexContexts = {}
  
  instances : {}
  singletons : {}
  subscriptions : []
  classes : {}
  applications:
    __loaded:
      scripts: {}
      styles: {}
      paths: {}
    ace :
      loaded  : 
        scripts : no
        styles  : yes
      path    : "js/apps/ace/"
      scripts :[ "ace-uncompressed.js","theme-twilight.js","mode-javascript.js" ]
      submodules:
        compilers:
          coffee: 
            scripts:['additional/coffee-script-compiler.js']
            
        modes:
          c_cpp: 
            scripts: ['mode-c_cpp.js']
          coffee: 
            scripts: ['mode-coffee.js']
          css: 
            scripts: ['mode-css.js']
          html:
            scripts: ['mode-html.js']
          java:
            scripts: ['mode-java.js']
          javascript:
            scripts: ['mode-javascript.js']
          json:
            scripts: ['mode-json.js']
          perl:
            scripts: ['mode-perl.js']
          php:
            scripts: ['mode-php.js']
          python:
            scripts: ['mode-python.js']
          scss:
            scripts: ['mode-scss.js']
          ruby:
            scripts: ['mode-ruby.js']
          svg:
            scripts: ['mode-svg.js']
          xml:
            scripts: ['mode-xml.js']
          groovy:
            scripts: ['mode-groovy.js']
          ocaml:
            scripts: ['mode-ocaml.js']
          scad:
            scripts: ['mode-scad.js']
          scala:
            scripts: ['mode-scala.js']
          coldfusion:
            scripts: ['mode-coldfusion.js']
          haxe:
            scripts: ['mode-haxe.js']
          latex:
            scripts: ['mode-latex.js']
          lua:
            scripts: ['mode-lua.js']
          markdown:
            scripts: ['mode-markdown.js']
          powershell:
            scripts: ['mode-powershell.js']
          sql:
            scripts: ['mode-sql.js']
        themes: 
          clouds:
            scripts: ['theme-clouds.js']
          clouds_midnight:
            scripts: ['theme-clouds_midnight.js']
          cobalt: 
            scripts: ['theme-cobalt.js']
          dawn: 
            scripts: ['theme-dawn.js']
          eclipse: 
            scripts: ['theme-eclipse.js']
          idle_fingers: 
            scripts: ['theme-idle_fingers.js']
          kr_theme: 
            scripts: ['theme-kr_theme.js']
          merbivore: 
            scripts: ['theme-merbivore.js']
          merbivore_soft: 
            scripts: ['theme-merbivore_soft.js']
          mono_industrial:
            scripts: ['theme-mono_industrial.js']
          monokai: 
            scripts: ['theme-monokai.js']
          pastel_on_dark: 
            scripts: ['theme-pastel_on_dark.js']
          twilight:
            scripts: ['theme-twilight.js']
          vibrant_ink: 
            scripts: ['theme-vibrant_ink.js']
          crimson_editor:
            scripts: ['theme-crimson_editor.js']
          solarized_dark:
            scripts: ['theme-solarized_dark.js']
          solarized_light:
            scripts: ['theme-solarized_light.js']
          tomorrow:
            scripts: ['theme-tomorrow.js']
          tomorrow_night:
            scripts: ['theme-tomorrow_night.js']
          tomorrow_night_blue:
            scripts: ['theme-tomorrow_night_blue.js']
          tomorrow_night_bright:
            scripts: ['theme-tomorrow_night_bright.js']
          tomorrow_night_eighties:
            scripts: ['theme-tomorrow_night_eighties.js']
          
      data:
        compilerCallNames: 
          coffee:
            class: 'CoffeeScript'
            method: 'compile'
            options: 
              bare: on
        syntaxExtensionAssociations: 
          php:          ['php', 'phtml']
          css:          ['css']
          javascript:   ['js']
          coffee:       ['coffee']
          c:            ['c_cpp']
          html:         ['html', 'htm', 'xhtml']
          java:         ['j', 'java']
          perl:         ['perl']
          python:       ['pyth']
          ruby:         ['rb']
          svg:          ['svg']
          xml:          ['xml']
          scss:         ['scss']
          
        fontSizes: [10, 11, 12, 14, 16, 20, 24]
        
        tabSizes: [2, 4, 8]
          
        syntaxes: [
            value: 'c_cpp'
            title: 'C++'
          ,
            value: 'javascript'
            title: 'Javascript'
          ,
            value: 'json'
            title: 'JSON'
          ,
            value: 'coffee'
            title: 'Coffee-script'
          ,
            value: 'css'
            title: 'CSS'
          ,
            value: 'html'
            title: 'HTML'
          ,
            value: 'java'
            title: 'Java'
          ,
            value: 'perl'
            title: 'Perl'
          ,
            value: 'php'
            title: 'PHP'
          ,
            value: 'python'
            title: 'Python'
          ,
            value: 'scss'
            title: 'SCSS'
          ,
            value: 'ruby'
            title: 'Ruby'
          ,
            value: 'svg'
            title: 'SVG'
          ,
            value: 'xml'
            title: 'XML'
          ,
            value: 'groovy'
            title: 'Groovy'
          ,
            value: 'ocaml'
            title: 'Ocaml'
          ,
            value: 'scad'
            title: 'Scad'
          ,
            value: 'scala'
            title: 'Scala'
          , 
            title: 'ColdFusion'
            value: 'coldfusion'
          , 
            value: 'haxe'
            title: 'Haxe'
          ,
            value: 'latex'
            title: 'Latex'
          ,
            title: 'Lua'
            value: 'lua'
          ,
            title: 'Markdown'
            value: 'markdown'
          ,
            title: 'PowerShell'
            value: 'powershell'
          ,
            title: 'SQL'
            value: 'sql'
          ].sort (a, b) ->
            if a.title < b.title then -1 else 1
        themes: [
            value: 'clouds'
            title: 'Clouds'
          ,
            value: 'clouds_midnight'
            title: 'Clouds Midnight'
          ,
            value: 'cobalt'
            title: 'Cobalt'
          ,
            value: 'dawn'
            title: 'Dawn'
          ,
            value: 'eclipse'
            title: 'Eclipse'
          ,
            value: 'idle_fingers'
            title: 'Idle Fingers'
          ,
            value: 'kr_theme'
            title: 'KR Theme'
          ,
            value: 'merbivore'
            title: 'Merbivore'
          ,
            value: 'merbivore_soft'
            title: 'Merbivore Soft'
          ,
            value: 'mono_industrial'
            title: 'Mono Industrial'
          ,
            value: 'monokai'
            title: 'Monokai'
          ,
            value: 'pastel_on_dark'
            title: 'Pastel On Dark'
          ,
            value: 'twilight'
            title: 'Twilight'
          ,
            value: 'vibrant_ink'
            title: 'Vibtrant Ink'
          ,
            value: 'crimson_editor'
            title: 'Crimson Editor'
          ,
            value: 'solarized_dark'
            title: 'Solarized Dark'
          ,
            value: 'solarized_light'
            title: 'Solarized Light'
          ,
            title: 'Tomorrow'
            value: 'tomorrow'
          ,
            title: 'Tomorrow Night'
            value: 'tomorrow_night'
          ,
            title: 'Tomorrow Night Blue'
            value: 'tomorrow_night_blue'
          ,
            title: 'Tomorrow Night Bright'
            value: 'tomorrow_night_bright'
          ,
            title: 'Tomorrow Night Eighties'
            value: 'tomorrow_night_eighties'
          ].sort (a, b) ->
            if a.title < b.title then -1 else 1
    shell :
      loaded  :
        scripts : no
        styles  : no
      path    : "js/apps/terminal/"
      scripts :["terminal.js","worker.js"]
      styles : ["terminal.css"]
    dnode :
      loaded  :
        scripts : no
        styles  : no
      path    : "js/apps/dnode/"
      scripts : ["index.js"]
      styles  : null
      

  # remote:(objectName)->
  #   return now[objectName] if now?.connected? #already connected to bongo.api.Site.js
  #   @nowQueue ?= []
  #   now[objectName] = {} #placeholder object
  #   blah = now[objectName]
  #   @nowQueue.push now[objectName]
  #   now[objectName] = {"blahblah"}
  #   blah.test = "chicken"
  #   log @nowQueue.push now[objectName].test

  setAuthKey:->

  requireLogin:(errMsg, callback)->
    [callback, errMsg] = [errMsg, callback] unless callback
    if KDObject::getSingleton("site").account?.data.item.profile.isGuest
      # KDView::handleEvent {type:"NavigationTrigger",pageName:"Login", appId:"Login"}
      new KDNotificationView
        type     : 'growl'
        title    : 'Access denied!'
        content  : errMsg or 'You must log in to perform this action!'
        duration : 3000
    else
      callback?()
  
  socketConnected:()->
    console.log "backend connected"
    @propagateEvent "KDBackendConnectedEvent"
      #   KD.connectQueue() #KD because this will be called in the context of bongo.api.Site.ready or something
      # 
      # connectQueue:()->
      #   return unless @nowQueue?.length > 0
      #   @propagateEvent "now Loaded",@nowQueue.pop()
      #   @connectQueue()
  
  setApplicationPartials:(partials)->
    @appPartials = partials

  subscribe : (subscription)->
    unless subscription.KDEventType.toLowerCase() is "resize"
      @subscriptions.push subscription

# FIXME: very wasteful way to remove subscriptions, vs. splice ??
  removeSubscriptions : (aKDViewInstance) ->
    newSubscriptions = for subscription,i in @subscriptions
      subscription if subscription.subscribingInstance isnt aKDViewInstance
    @recreateSubscriptions newSubscriptions

  recreateSubscriptions:(newSubscriptions)->
    @subscriptions = []
    for subscription in newSubscriptions
      @subscriptions.push subscription if subscription?
  
  getAllSubscriptions: ->
    @subscriptions

  registerInstance : (anInstance)->
    warn "Instance being overwritten!!", anInstance  if @instances[anInstance.id]
    @instances[anInstance.id] = anInstance
    @classes[anInstance.constructor.name] ?= anInstance.constructor
  
  unregisterInstance: (anInstance)->
    # warn "Instance being unregistered doesn't exist in registry!!", anInstance unless @instances[anInstance.id]
    delete @instances[anInstance.id]
  
  deleteInstance:(anInstance)->
    @unregisterInstance anInstance
    # anInstance = null #FIXME: Redundant? See unregisterInstance
  
  registerSingleton:(singletonName,object,override = no)->
    if (existingSingleton = KD.singletons[singletonName])?
      if override
        warn "singleton overriden! KD.singletons[\"#{singletonName}\"]"
        existingSingleton.destroy?()
        KD.singletons[singletonName] = object
      else
        error "singleton exists! if you want to override set override param to true]"
        KD.singletons[singletonName]
    else
      console.log "singleton registered! KD.singletons[\"#{singletonName}\"]"
      KD.singletons[singletonName] = object
      
  getSingleton:(singletonName)->
    if KD.singletons[singletonName]?
      KD.singletons[singletonName] 
    else
      warn "singleton doesn't exist!"
      null
  
  emptyDataCache:()->
    for own id,object of @getAllKDInstances
      if object instanceof KDData
        object.destroy()
  
  getUniqueId:->
    "#{__utils.getRandomNumber(100000)}_#{Date.now()}"
  
  getAllKDInstances:()-> KD.instances

  getKDViewInstanceFromDomElement:(domElement)->
    @instances[domElement.getAttribute("data-id")]

  propagateEvent: (KDEventType, publishingInstance, value)->
    for subscription in @subscriptions
      if (!KDEventType? or !subscription.KDEventType? or !!KDEventType.match(subscription.KDEventType.capitalize()))
        subscription.callback.call subscription.subscribingInstance, publishingInstance, value, {subscription}

  requirePathExists: (appId) ->
    [app, modulePathItems...] = appId.split '/'
    
    endpoint        = @applications[app]?.submodules
    for item in modulePathItems
      endpoint = endpoint[item]
      
    if endpoint
      yes
    else
      no
         
  require: (path, callback) ->
    [app, modulePathItems...] = path.split '/'
    
    loadStack = []
    
    #searching for submodule  
    endpoint        = @applications[app].submodules
    loadSubModules  = no
    for item in modulePathItems
      loadSubModules = yes
      endpoint = endpoint[item] #module endpoint
    
    loadStack.push (callback) =>
      @__loadScripts app, @applications[app], callback
      
    loadStack.push (callback) =>
      @__loadStyles app, @applications[app], callback
      
    if loadSubModules
      loadStack.push (callback) =>
        @__loadScripts app, endpoint, callback
      loadStack.push (callback) =>
        @__loadStyles app, endpoint, callback
        
    #fire!  
    async.series loadStack, (error, result) =>
      callback()
      
  __loadScripts: (app, container, callback) ->
    @__loadItems app, container, 'scripts', callback
    
  __loadStyles: (app, container, callback) ->
    @__loadItems app, container, 'styles', callback
      
  __loadItems:(app, itemsContainer, itemsType, callback)->
    itemsLoader = async.queue ((path, callback) ->
      if KD.applications.__loaded[itemsType][path] isnt yes #script isnt loaded, it is in process or not event started
        emitter = KD.applications.__loaded.paths[path] or= new BasicEmitter
        emitter.on path, ->
          callback()
        if KD.applications.__loaded[itemsType][path] is 'in process'
          console.log 'script in process, waiting for emitter :::' + path
        else          
          KD.applications.__loaded[itemsType][path] = 'in process'
          if itemsType is 'scripts'
            # $.ajax
            #   url: path
            #   dataType: 'text'
            #   error: (e, a)->
            #     log 'got err', e, a
            #   success: (content, status) ->
            #     with window
            #       eval content, window
            #     catch e
            #       log 'evaled with error', e
            #     KD.applications.__loaded[itemsType][path] = yes
            #     emitter.emit path
                
            getter = $.getScript path,()->   #this one stopped working, i guess something wrong with headers
              console.log 'path loaded:::' + path
              KD.applications.__loaded[itemsType][path] = yes
              emitter.emit path
            getter.error (r, e) ->
              console.log 'cannot load path::' + path + ' with error::', e
              KD.applications.__loaded[itemsType][path] = yes
              emitter.emit path
          else if itemsType is 'styles'
            $.getCss path, ->
              console.log 'path loaded:::' + path
              KD.applications.__loaded[itemsType][path] = yes
              emitter.emit path
          else
            console.log 'unknown file load type:' + itemsType
      else
        callback()
      ), 1
      
    
    itemsLoader.drain = ->
      callback()
  
    return callback() unless itemsContainer[itemsType]
    for path in itemsContainer[itemsType]
      itemsLoader.push @applications[app].path + path
      
  getAppData: (app) ->
     if @applications[app].data
       @applications[app].data
      else
        {}
        
  # Get next highest Z-index
  getNextHighestZIndex:(context)->
   uniqid = context.attr 'data-id'
   if isNaN zIndexContexts[uniqid]
     zIndexContexts[uniqid] = 0
   else
     zIndexContexts[uniqid]++
  
  jsonhTest:->
    method    = 'fetchQuestionTeasers'
    testData  = {
      foo: 10
      bar: 11
    }
    
    start = Date.now()
    $.ajax "/#{method}.jsonh",
      data     : testData
      dataType : 'jsonp'
      success : (data)->
        inflated = JSONH.unpack data
        console.log 'success', inflated
        console.log Date.now()-start
  
  registerPage:(name,classFunction)->
    # log "registering a page",name
    @pageClasses ?= {}
    @pageClasses[name] = classFunction

  getPage:(name)->
    @pageClasses[name]

requirejs ['Framework', 'AppController', 'text!app.css', 'text!test.js', 'libs/async', 'libs/jquery-1.7.1'], (framework, appInstance, css, testFileContents)->
  KD.registerSingleton "windowController", new framework.KDWindowController()
  listener = new framework.KDObject()

  listener.listenTo KDEventTypes : ['ApplicationInitialized'], callback:->
    testFile =
      contents: testFileContents
      path: '/test.js'
    appInstance.openFile testFile
  
  listener.listenTo KDEventTypes : ['ApplicationWantsToBeShown'], callback: (app, {options, data})->
    $("<style type='text/css'>#{css}</style>").appendTo("head");
    framework.KDView.appendToDOMBody mainView = new framework.KDView()
    mainView.addSubView data

  appInstance.initApplication()