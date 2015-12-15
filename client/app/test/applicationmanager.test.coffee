kd                 = require 'kd'
expect             = require 'expect'
globals            = require 'globals'
AppController      = require '../lib/appcontroller'
registerAppClass   = require '../lib/util/registerAppClass'
ApplicationManager = require '../lib/applicationmanager'
appManager         = null


describe 'ApplicationManager', ->


  beforeEach -> appManager = new ApplicationManager


  it 'should work', -> expect(appManager).toBeA ApplicationManager


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


  describe '::get', ->

    it 'should return null if there is no appControllers', ->
      expect(appManager.get('foo')).toBe.null

    it 'should return app', ->
      appManager.register fooApp = new AppController name: 'FooApp'
      expect(appManager.get('FooApp')).toEqual fooApp


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
        expect(isRegistered).toBe yes, 'isRegistered'
        expect(isCallbackExecuted).toBe yes, 'isCallbackExecuted'
        expect(appManager.appControllers.FakeApp.instances).toInclude createdAppInstance
        done()
