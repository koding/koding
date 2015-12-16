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


  describe 'constructor', ->

    it 'should be instantiated', -> expect(appManager).toBeA ApplicationManager


  describe '::register', ->

    it 'should have appControllers with registered app name', ->

      isRegistered = no
      appInstance  = new AppController name: 'FooApp'
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
      appManager.register fooApp = new AppController name: 'FooApp'
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

      isAppCreated       = no
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

      globals.config.apps.InternalApp = name: 'InternalApp'
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
