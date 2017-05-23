kd            = require 'kd'
nick          = require 'app/util/nick'
mock          = require '../../mocks/mockingjay'
expect        = require 'expect'
routes        = require '../lib/routes'

appManager    = kd.singletons.appManager
mockMachine   = mock.getMockMachine()
mockWorkspace = mock.getMockWorkspace()
dataToLoadIDE =
  machine     : mock.getMockMachine()
  username    : mock.getMockAccount().profile.nickname
  workspace   : mock.getMockWorkspace()
  channelId   : '6075644514008039523'

ROUTE_PARAMS           =
  machine              : { params: { machineLabel: 'aws-vm-0' } }
  noMachine            : { params: { machineLabel: 'not-existing-machine' } }
  workspace            : { params: { machineLabel: 'aws-vm-0', workspaceSlug: 'my-workspace' } }
  noWorkspace          : { params: { machineLabel: 'aws-vm-0', workspaceSlug: 'not-existing-workspace' } }
  collaboration        : { params: { machineLabel: '6075649037833338981' } }
  noMachineNoWorkspace : { params: { machineLabel: 'not-existing-machine', workspaceSlug: 'not-existing-workspace' } }


createSpyAndAssert = (spyOn, spyFor, routeType, routeParams) ->

  expect.spyOn spyOn, spyFor
  routes.routeHandler routeType, routeParams

  expect(spyOn[spyFor]).toHaveBeenCalled()


getStorageData = ->

  storage        = kd.singletons.localStorageController.storage 'IDE'
  storageData    =
    machineLabel : mockMachine.slug
    workspaceSlug: mockWorkspace.slug
    channelId    : undefined

  return { storage, storageData }


describe 'IDE.routes', ->

  afterEach -> expect.restoreSpies()


  describe '.routeHandler', ->

    describe 'when machine, eg. /IDE/6075649037833338981 or /IDE/aws-vm-0', ->

      it 'should routeToMachine if machine is fetched', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()

        expect.spyOn routes, 'routeToMachine'
        routes.routeHandler 'machine', ROUTE_PARAMS.machine
        expect(routes.routeToMachine).toHaveBeenCalled()


    describe 'when workspace, eg. IDE/aws-vm-0/my-workspace', ->

      it 'should routeToMachine if workspace is not found', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()

        expect.spyOn routes, 'routeToMachine'

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(routes.routeToMachine).toHaveBeenCalled()


  describe '.loadIDENotFound', ->

    it 'should tell ide instance to createMachineStateModal with NotFound state', ->

      fakeApp = {}

      expect.spyOn(appManager, 'open').andCall (appName, options, callback) -> callback fakeApp
      expect.spyOn appManager, 'tell'

      routes.loadIDENotFound()

      expect(fakeApp.amIHost).toBe yes
      expect(appManager.open).toHaveBeenCalled()
      expect(appManager.tell).toHaveBeenCalledWith 'IDE', 'createMachineStateModal', { state: 'NotFound' }


  describe '.loadIDE', ->

    testLoadIDEInnerCallback = (callback) ->

      spy     = expect.spyOn(appManager, 'open').andCall (appName, options, callback) -> callback fakeApp
      { uid } = mockMachine
      fakeApp = { mountMachineByMachineUId: -> }

      mock.ideRoutes.findInstance.toReturnNull()
      expect.spyOn fakeApp, 'mountMachineByMachineUId'

      callback()

      expect(appManager.open).toHaveBeenCalled()
      expect(spy.calls.first.arguments[0]).toBe 'IDE'
      expect(spy.calls.first.arguments[1].forceNew).toBe yes
      expect(fakeApp.mountMachineByMachineUId).toHaveBeenCalledWith uid
      expect(fakeApp.mountedMachineUId).toBe uid

      if nick() is dataToLoadIDE.username
        expect(fakeApp.amIHost).toBe yes
      else
        expect(fakeApp.isInSession).toBe       yes
        expect(fakeApp.amIHost).toBe           no
        expect(fakeApp.collaborationHost).toBe dataToLoadIDE.username
        expect(fakeApp.channelId).toBe         dataToLoadIDE.channelId


    it 'should selectWorkspaceOnSidebar', ->

      expect.spyOn routes, 'selectWorkspaceOnSidebar'

      routes.loadIDE dataToLoadIDE

      expect(routes.selectWorkspaceOnSidebar).toHaveBeenCalledWith dataToLoadIDE


    it 'should showInstance if ide is already opened', ->

      mock.ideRoutes.findInstance.toReturnInstance()
      expect.spyOn appManager, 'showInstance'
      expect.spyOn routes, 'selectWorkspaceOnSidebar'
      appManager.appControllers.IDE = {}
      appManager.appControllers.IDE.instances = []

      routes.loadIDE dataToLoadIDE

      expect(appManager.showInstance).toHaveBeenCalled()
      expect(routes.selectWorkspaceOnSidebar).toHaveBeenCalled()


    it 'should open IDE if there is no open ide app instance', ->

      appManager.appControllers.IDE = null

      testLoadIDEInnerCallback -> routes.loadIDE dataToLoadIDE


    it 'should open IDE if ide instance not found but there is open ide instances', ->

      appManager.appControllers.IDE = {}
      appManager.appControllers.IDE.instances = []

      testLoadIDEInnerCallback -> routes.loadIDE dataToLoadIDE


  describe '.findInstance', ->


    it 'should return undefined if there is no ide app instance', ->

      appManager.appControllers.IDE = { instances: [] }

      instance = routes.findInstance mockMachine, { getId: -> }

      expect(instance).toBe undefined


    it 'should return the appInstance if there is a match', ->

      ws = {}
      ws[key]  = value for own key, value of mockWorkspace
      ws.getId = -> ws._id

      appManager.appControllers.IDE =
        instances: [
          {
            foo              : 'bar'
            mountedMachineUId: mockMachine.uid
          }
        ]

      instance = routes.findInstance mockMachine, ws
      expect(instance.foo).toBe 'bar'
