kd            = require 'kd'
mock          = require '../../mocks/mockingjay'
expect        = require 'expect'
routes        = require '../lib/routes'
dataProvider  = require 'app/userenvironmentdataprovider'

mockMachine   = mock.getMockMachine()
mockWorkspace = mock.getMockWorkspace()

ROUTE_PARAMS           =
  machine              : { params: { machineLabel: 'koding-vm-0' } }
  noMachine            : { params: { machineLabel: 'not-existing-machine' } }
  workspace            : { params: { machineLabel: 'koding-vm-0', workspaceSlug: 'my-workspace' } }
  noWorkspace          : { params: { machineLabel: 'koding-vm-0', workspaceSlug: 'not-existing-workspace' } }
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

    describe 'when home, eg. /IDE', ->

      it 'should routeToLatestWorkspace', ->

        createSpyAndAssert routes, 'routeToLatestWorkspace', 'home'


    describe 'when machine, eg. /IDE/6075649037833338981 or /IDE/koding-vm-0', ->

      it 'should loadCollaborativeIDE if machine label is all digits which we assume it is a channel id related with a collaboration session', ->

        createSpyAndAssert routes, 'loadCollaborativeIDE', 'machine', ROUTE_PARAMS.collaboration


      it 'should fetch machine if machine label contains chars', ->

        createSpyAndAssert dataProvider, 'fetchMachine', 'machine', ROUTE_PARAMS.machine


      it 'should routeToMachineWorkspace if machine is fetched', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()

        expect.spyOn routes, 'routeToMachineWorkspace'
        routes.routeHandler 'machine', ROUTE_PARAMS.machine
        expect(routes.routeToMachineWorkspace).toHaveBeenCalled()


      it 'should routeToLatestWorkspace if no machine is fetched', ->

        mock.envDataProvider.fetchMachine.toReturnNull()
        expect.spyOn routes, 'routeToLatestWorkspace'
        routes.routeHandler 'machine', ROUTE_PARAMS.noMachine
        expect(routes.routeToLatestWorkspace).toHaveBeenCalled()


    describe 'when workspace, eg. IDE/koding-vm-0/my-workspace', ->

      it 'should fetchMachine for the given machine id', ->

        createSpyAndAssert dataProvider, 'fetchMachine', 'workspace', ROUTE_PARAMS.workspace


      it 'should ensureDefaultWorkspace', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()
        mock.envDataProvider.ensureDefaultWorkspace()

        expect.spyOn dataProvider, 'ensureDefaultWorkspace'
        expect.spyOn dataProvider, 'fetchWorkspaceByMachineUId' # to prevent ide load and url change

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(dataProvider.ensureDefaultWorkspace).toHaveBeenCalled()
        expect(dataProvider.fetchWorkspaceByMachineUId).toHaveBeenCalled()


      it 'should routeToLatestWorkspace if there is no machine', ->

        mock.envDataProvider.fetchMachine.toReturnNull()
        mock.envDataProvider.ensureDefaultWorkspace()

        expect.spyOn routes, 'routeToLatestWorkspace'

        routes.routeHandler 'workspace', ROUTE_PARAMS.noMachineNoWorkspace
        expect(routes.routeToLatestWorkspace).toHaveBeenCalled()


      it 'should fetchWorkspaceByMachineUId', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()
        mock.envDataProvider.ensureDefaultWorkspace()

        expect.spyOn dataProvider, 'fetchWorkspaceByMachineUId'

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(dataProvider.fetchWorkspaceByMachineUId).toHaveBeenCalled()


      it 'should loadIDE if machine and workpsace is found', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()
        mock.envDataProvider.ensureDefaultWorkspace()
        mock.envDataProvider.fetchWorkspaceByMachineUId.toReturnWorkspace()

        expect.spyOn routes, 'loadIDE'

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(routes.loadIDE).toHaveBeenCalled()


      it 'should routeToMachineWorkspace if workspace is not found', ->

        mock.envDataProvider.fetchMachine.toReturnMachine()
        mock.envDataProvider.ensureDefaultWorkspace()
        mock.envDataProvider.fetchWorkspaceByMachineUId.toReturnNull()

        expect.spyOn routes, 'routeToMachineWorkspace'

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(routes.routeToMachineWorkspace).toHaveBeenCalled()


  describe '.selectWorkspaceOnSidebar', ->

    it 'should return safely if there is no machine or workspace', ->

      calls = [
        routes.selectWorkspaceOnSidebar()
        routes.selectWorkspaceOnSidebar {}
        routes.selectWorkspaceOnSidebar { machine: {} }
        routes.selectWorkspaceOnSidebar { workspace: {} }
      ]

      expect(call).toBe no  for call in calls


    it 'should call activitySidebar.selectWorkspace', ->

      data                     = { machine: mockMachine, workspace: mockWorkspace }
      { activitySidebar }      = kd.singletons.mainView
      { storage, storageData } = getStorageData()

      sidebarSpy = expect.spyOn activitySidebar, 'selectWorkspace'
      storageSpy = expect.spyOn storage, 'setValue'

      routes.selectWorkspaceOnSidebar data

      expect(activitySidebar.selectWorkspace).toHaveBeenCalled()
      expect(storage.setValue).toHaveBeenCalled()

      [ firstCall, secondCall ] = storageSpy.calls

      expect(firstCall.arguments[0]).toBe 'LatestWorkspace'
      expect(firstCall.arguments[1]).toEqual storageData

      expect(secondCall.arguments[0]).toBe "LatestWorkspace_#{mockMachine.uid}"
      expect(secondCall.arguments[1]).toEqual storageData


  describe '.getLatestWorkspace', ->

    it 'should return safely if there is no workspace', ->

      expect(routes.getLatestWorkspace()).toBe no
      expect(routes.getLatestWorkspace({ uid: 'foo' })).toBe no


    it 'should find the latest workspace', ->

      { storage, storageData } = getStorageData()

      expect.spyOn(storage, 'getValue').andCall -> return storageData
      mock.envDataProvider.findWorkspace.toReturnWorkspace()

      { machineLabel, workspaceSlug, channelId } = storageData

      workspace = routes.getLatestWorkspace mockMachine

      expect(dataProvider.findWorkspace).toHaveBeenCalledWith machineLabel, workspaceSlug, channelId
      expect(workspace).toEqual storageData


    it 'should return undefined if there is no workspace found for the storaged data in localStorage', ->

      { storage, storageData } = getStorageData()

      expect.spyOn(storage, 'getValue').andCall -> return storageData
      mock.envDataProvider.findWorkspace.toReturnNull()

      workspace = routes.getLatestWorkspace mockMachine

      expect(storage.getValue).toHaveBeenCalled()
      expect(workspace).toEqual undefined


  describe '.loadIDENotFound', ->

    it 'should tell ide instance to createMachineStateModal with NotFound state', ->

      fakeApp        = {}
      { appManager } = kd.singletons

      expect.spyOn(appManager, 'open').andCall (appName, options, callback) -> callback fakeApp
      expect.spyOn appManager, 'tell'

      routes.loadIDENotFound()

      expect(fakeApp.amIHost).toBe yes
      expect(appManager.open).toHaveBeenCalled()
      expect(appManager.tell).toHaveBeenCalledWith 'IDE', 'createMachineStateModal', state: 'NotFound'


  describe '.routeToFallback', ->


    it 'should routeToMachineWorkspace if there is a machine', ->

      mock.envDataProvider.getMyMachines.toReturnMachines()
      expect.spyOn routes, 'routeToMachineWorkspace'

      routes.routeToFallback()
      expect(routes.routeToMachineWorkspace).toHaveBeenCalledWith mockMachine


    it 'should loadIDENotFound if there is no machine', ->

      mock.envDataProvider.getMyMachines.toReturnEmptyArray()
      expect.spyOn routes, 'loadIDENotFound'

      routes.routeToFallback()
      expect(routes.loadIDENotFound).toHaveBeenCalled()
