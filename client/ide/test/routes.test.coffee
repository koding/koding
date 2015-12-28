kd           = require 'kd'
mock         = require '../../mocks/mockingjay'
expect       = require 'expect'
routes       = require '../lib/routes'
dataProvider = require 'app/userenvironmentdataprovider'


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

        routes.routeHandler 'workspace', ROUTE_PARAMS.workspace
        expect(dataProvider.ensureDefaultWorkspace).toHaveBeenCalled()


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
