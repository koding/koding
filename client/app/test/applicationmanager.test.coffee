kd                   = require 'kd'
expect               = require 'expect'
globals              = require 'globals'
AppController        = require '../lib/appcontroller'
registerAppClass     = require '../lib/util/registerAppClass'
ApplicationManager   = require '../lib/applicationmanager'
KodingAppsController = require '../lib/kodingappscontroller'

appManager = null
createApps = (appNames = [], shouldShow) ->

  appNames.forEach (name) ->
    registerAppClass AppController, { name }

    appManager.create name
    appManager.show   name  if shouldShow


describe 'kd.singletons.appManager', ->


  beforeEach -> appManager = new ApplicationManager


  afterEach -> expect.restoreSpies()


  describe 'constructor', ->

    it 'should be instantiated', -> expect(appManager).toBeA ApplicationManager


  describe '::register', ->

    it 'should have appControllers with registered app name', ->

      isRegistered = no
      appInstance  = new AppController { name: 'FooApp' }
      expect.spyOn appManager, 'setListeners'

      appManager.on 'AppRegistered', -> isRegistered = yes
      appManager.register appInstance

      expect(appManager.appControllers.FooApp.instances).toInclude appInstance
      expect(appManager.setListeners).toHaveBeenCalled()
      expect(isRegistered).toBe yes


  describe '::unregister', ->


    it 'should return no if there is no app for the given instance', ->

      createApps [ 'TestApp' ], yes
      expect(appManager.unregister new kd.View).toBe no


    it 'should unregister the given app instance', ->

      unregisteredAppName = null

      createApps [ 'AppName1', 'AppName2' ], yes
      appManager.create 'AppName2', { forceNew: yes }

      appManager.on 'AppUnregistered', (name) -> unregisteredAppName = name

      expect(appManager.appControllers.AppName2.instances.length).toBe 2

      appManager.unregister appManager.get 'AppName1'
      expect(appManager.appControllers.AppName1).toBe undefined
      expect(unregisteredAppName).toBe 'AppName1'

      appManager.unregister appManager.get 'AppName2'
      expect(appManager.appControllers.AppName2.instances.length).toBe 1
      expect(unregisteredAppName).toBe 'AppName2'
      expect(appManager.appControllers.AppName2).toExist()

      appManager.unregister appManager.get 'AppName2'
      expect(appManager.appControllers.AppName2).toBe undefined
      expect(unregisteredAppName).toBe 'AppName2'


  describe '::get', ->

    it 'should return null if there is no appControllers', ->
      expect(appManager.get('foo')).toBe null


    it 'should return app', ->
      appManager.register fooApp = new AppController { name: 'FooApp' }
      expect(appManager.get('FooApp')).toEqual fooApp


  describe '::getFrontApp', ->

    it 'should return the front app instance', ->

      createApps [ 'FrontApp', 'BackApp' ]

      appManager.show 'FrontApp'
      expect(appManager.getFrontApp().options.name).toBe 'FrontApp'

      appManager.show 'BackApp'
      expect(appManager.getFrontApp().options.name).toBe 'BackApp'


  describe '::getByView', ->

    it 'should return null if the given view doesnt belong to an app instance', ->

      appInstance = appManager.getByView new kd.View
      expect(appInstance).toBe null


    it 'should return the app instance by given app view', ->

      createApps [ 'MyApp' ], yes

      [ appInstance ] = appManager.appControllers.MyApp.instances
      appInstanceView = appInstance.getView()

      expect(appManager.getByView appInstanceView).toBe appInstance


  describe '::tell', ->

    it 'should warn if there is no name', ->

      expect.spyOn kd, 'warn'

      appManager.tell()
      expect(kd.warn).toHaveBeenCalled()


    it 'should directly call the method of the app if app is created', ->

      isMethodCalled = no
      methodParam1   = null
      methodParam2   = null

      createApps [ 'TellApp' ], yes

      AppController::someMethod = (p1, p2) ->
        isMethodCalled = yes
        methodParam1   = p1
        methodParam2   = p2

      appManager.tell 'TellApp', 'someMethod', 'FB', 1907

      kd.utils.defer ->
        expect(methodParam1).toBe 'FB'
        expect(methodParam2).toBe 1907
        expect(isMethodCalled).toBe yes


    it 'should create app if app is not created', ->

      isMethodCalled = no
      methodParam1   = null
      methodParam2   = null

      registerAppClass AppController, { name: 'NotCreatedApp' }

      AppController::someAnotherMethod = (p1, p2) ->
        isMethodCalled = yes
        methodParam1   = p1
        methodParam2   = p2

      appManager.tell 'NotCreatedApp', 'someAnotherMethod', 2011, '2014'

      kd.utils.defer ->
        expect(methodParam1).toBe 2011
        expect(methodParam2).toBe '2014'
        expect(isMethodCalled).toBe yes


  describe '::create', ->

    it 'should emit AppCouldntBeCreated event when app is not created', (done) ->

      isRegistered   = no
      isEventEmitted = no

      appManager.on 'AppRegistered',       -> isRegistered   = yes
      appManager.on 'AppCouldntBeCreated', -> isEventEmitted = yes
      appManager.create 'HelloApp'

      kd.utils.defer ->
        expect(isRegistered).toBe no
        expect(isEventEmitted).toBe yes
        done()


    it 'should create app if app config exists in globals', (done) ->

      isRegistered       = no
      isCallbackExecuted = no
      createdAppInstance = null

      registerAppClass kd.Object, { name: 'FakeApp' }
      appManager.on 'AppRegistered', -> isRegistered = yes

      appManager.create 'FakeApp', {}, (appInstance) ->
        isCallbackExecuted = yes
        createdAppInstance = appInstance

      kd.utils.defer ->
        expect(isRegistered).toBe yes
        expect(isCallbackExecuted).toBe yes
        expect(appManager.appControllers.FakeApp.instances).toInclude createdAppInstance
        done()


    it 'should load app', (done) ->

      globals.config.apps.InternalApp = { name: 'InternalApp' }
      expect.spyOn KodingAppsController, 'loadInternalApp'

      appManager.create 'InternalApp', {}

      kd.utils.defer ->
        expect(KodingAppsController.loadInternalApp).toHaveBeenCalled()
        done()


  describe '::show', ->

    it 'should show the app', (done) ->

      isAppShown                   = no
      isCallbackExecuted           = no
      isAppIsShownCallbackExecuted = no

      createApps [ 'FooApp', 'BarApp' ]

      appManager.on 'AppIsBeingShown', -> isAppShown = yes
      expect.spyOn appManager, 'setLastActiveIndex'

      appManager.appControllers.FooApp.instances.first.appIsShown = ->
        isAppIsShownCallbackExecuted = yes

      expect(isAppShown).toBe no

      appManager.show 'FooApp', {}, -> isCallbackExecuted = yes

      kd.utils.defer ->
        expect(isAppShown).toBe yes
        expect(isCallbackExecuted).toBe yes
        expect(isAppIsShownCallbackExecuted).toBe yes
        expect(appManager.setLastActiveIndex).toHaveBeenCalled()
        expect(appManager.getFrontApp().getOptions().name).toBe 'FooApp'

        appManager.show 'BarApp', {}, ->
          expect(appManager.getFrontApp().getOptions().name).toBe 'BarApp'
          done()


  describe '::showInstance', ->

    it 'should show the given app instance', (done) ->

      isCallbackExecuted           = no
      isEventEmitted               = no
      isAppIsShownCallbackExecuted = no

      createApps [ 'App1', 'App2', 'App3' ], yes
      appManager.on 'AppIsBeingShown', -> isEventEmitted = yes
      expect.spyOn appManager, 'setLastActiveIndex'

      expect(appManager.getFrontApp().options.name).toBe 'App3'

      app2 = appManager.get 'App2'

      appManager.appControllers.App2.instances.first.appIsShown = ->
        isAppIsShownCallbackExecuted = yes

      appManager.showInstance app2, -> isCallbackExecuted = yes

      kd.utils.defer ->
        expect(isCallbackExecuted).toBe yes
        expect(isEventEmitted).toBe yes
        expect(isAppIsShownCallbackExecuted).toBe yes
        expect(appManager.setLastActiveIndex).toHaveBeenCalled()
        done()

    it 'should not show the app if it is a background app', ->

      createApps [ 'MyApp1' ], yes
      registerAppClass AppController, { name: 'BackgroundApp', background: yes }
      appManager.create 'BackgroundApp'

      appManager.show 'MyApp1'
      expect(appManager.getFrontApp().options.name).toBe 'MyApp1'

      appManager.showInstance appManager.appControllers.BackgroundApp.instances.first
      expect(appManager.getFrontApp().options.name).toBe 'MyApp1'

      appManager.show 'BackgroundApp'
      expect(appManager.getFrontApp().options.name).toBe 'MyApp1'


  describe '::quit', ->

    it 'should quit the given app instance', (done) ->

      isBeforeQuitCalled = no

      createApps [ 'AwesomeApp', 'BadApp' ]

      { appControllers } = appManager
      awesomeInstances   = appControllers.AwesomeApp.instances
      badInstances       = appControllers.BadApp.instances

      expect(awesomeInstances.length).toBe 1
      expect(badInstances.length).toBe 1

      badInstance = badInstances.first
      badInstance.beforeQuit = -> isBeforeQuitCalled = yes

      appManager.quit badInstance, ->
        expect(isBeforeQuitCalled).toBe yes
        expect(badInstances.length).toBe 0
        expect(appControllers.BadApp).toBe undefined

        done()


  describe '::quitAll', ->

    it 'should quit all apps', ->

      createApps [ 'AnotherApp', 'YetAnotherApp' ]

      expect(Object.keys(appManager.appControllers).length).toBe 2

      appManager.quitAll()

      expect(Object.keys(appManager.appControllers).length).toBe 0


  describe '::quitByName', ->

    it 'should quit an app by name', ->

      createApps [ 'FooBarApp', 'BarFooApp' ]

      expect(Object.keys(appManager.appControllers).length).toBe 2

      appManager.quitByName 'FooBarApp'

      expect(Object.keys(appManager.appControllers).length).toBe 1

      appManager.quitByName 'BarFooApp'

      expect(Object.keys(appManager.appControllers).length).toBe 0


    it 'should quit all instances of given name', (done) ->

      createApps [ 'MultipleInstanceApp' ], yes
      appManager.create 'MultipleInstanceApp', { forceNew: yes }

      expect(Object.keys(appManager.appControllers).length).toBe 1
      expect(Object.keys(appManager.appControllers.MultipleInstanceApp.instances).length).toBe 2

      appManager.quitByName 'MultipleInstanceApp', ->
        expect(Object.keys(appManager.appControllers).length).toBe 0
        done()


  describe '::open', ->

    it 'should warn if open called with no name', ->

      expect.spyOn(kd, 'warn')
      appManager.open()
      expect(kd.warn).toHaveBeenCalled()


    it 'should open app a registed but not created app', ->

      registerAppClass AppController, { name: 'OpenApp' }
      expect(appManager.appControllers.OpenApp).toBe undefined

      appManager.open 'OpenApp'
      expect(appManager.appControllers.OpenApp.instances.length).toBe 1


    it 'should open an already created app', ->

      createApps [ 'CreatedApp' ]

      appManager.open 'CreatedApp'
      expect(appManager.appControllers.CreatedApp.instances.length).toBe 1
      expect(appManager.getFrontApp().getOptions().name).toBe 'CreatedApp'


    it 'should open the another instance of the same app if forceNew option is true', (done) ->

      isCallbackExecuted = no

      createApps [ 'MultipleApp' ], yes
      expect(appManager.appControllers.MultipleApp.instances.length).toBe 1
      expect(appManager.getFrontApp().getOptions().name).toBe 'MultipleApp'

      globals.appClasses.MultipleApp.options.multiple = yes
      appManager.open 'MultipleApp', { forceNew: yes }, ->
        isCallbackExecuted = yes

      kd.utils.wait 333, ->
        expect(appManager.appControllers.MultipleApp.instances.length).toBe 2
        expect(isCallbackExecuted).toBe yes
        done()


    it 'should check pre condition of the app before opening it', (done) ->

      isConditionExecuted = no

      registerAppClass AppController,
        name         : 'PreConditionApp'
        preCondition :
          condition  : (o, cb) ->
            isConditionExecuted = yes
            cb yes

      appManager.open 'PreConditionApp'

      kd.utils.wait 333, ->
        expect(isConditionExecuted).toBe yes
        expect(appManager.appControllers.PreConditionApp.instances.length).toBe 1
        done()


    it 'should call failure method and should not open app if pre condition fail', (done) ->

      isConditionExecuted = no
      isFailureExecuted   = no

      registerAppClass AppController,
        name: 'FailConditionApp'
        preCondition:
          condition: (o, cb) ->
            isConditionExecuted = yes
            cb no
          failure: -> isFailureExecuted = yes

      appManager.open 'FailConditionApp'

      kd.utils.wait 333, ->
        expect(isConditionExecuted).toBe yes
        expect(isFailureExecuted).toBe yes
        expect(appManager.appControllers.FailConditionApp).toBe undefined
        done()


  describe '::isAppInternal', ->

    it 'should return yes if app is internal', ->

      globals.config.apps.MyAwesomeInternalApp = {}
      expect(appManager.isAppInternal 'MyAwesomeInternalApp').toBe yes


    it 'should return no if no such app', ->
      expect(appManager.isAppInternal 'FooApp').toBe no


    it 'should return no if no app name provided', ->
      expect(appManager.isAppInternal()).toBe no


  describe '::isAppLoaded', ->

    it 'should return yes if app is already loaded', ->

      globals.appClasses.DifferentApp = {}
      expect(appManager.isAppLoaded 'DifferentApp').toBe yes


    it 'should return no if no such app', ->
      expect(appManager.isAppLoaded 'BazApp').toBe no


    it 'should return no if no app name provided', ->
      expect(appManager.isAppLoaded()).toBe no


  describe '::shouldLoadApp', ->

    it 'should return yes if app is internal and not loaded', ->
      globals.config.apps.ICantFindANameAnymoreApp = {}

      expect(appManager.shouldLoadApp('ICantFindANameAnymoreApp')).toBe yes


    it 'should return no if app is not an internal app', ->

      expect(appManager.shouldLoadApp('NotInternalApp')).toBe no


    it 'should return no if app is an internal app but it is already loaded', ->

      globals.config.apps.LoadedApp = {}
      globals.appClasses.LoadedApp  = {}
      expect(appManager.shouldLoadApp('LoadedApp')).toBe no


    it 'should return no if no app name provided', ->
      expect(appManager.shouldLoadApp()).toBe no
