kd           = require 'kd'
expect       = require 'expect'
routes       = require '../lib/routes'
dataProvider = require 'app/userenvironmentdataprovider'

spy             = null
ROUTE_PARAMS    =
  machine       : { params: { machineLabel: 'koding-vm-0' } }
  noMachine     : { params: { machineLabel: 'not-existing-machine' } }
  workspace     : { params: { machineLabel: 'koding-vm-0', workspaceSlug: 'my-workspace' } }
  noWorkspace   : { params: { machineLabel: 'koding-vm-0', workspaceSlug: 'not-existing-workspace' } }
  collaboration : { params: { machineLabel: '6075649037833338981' } }


createSpyAndAssert = (spyOn, spyFor, routeType, routeParams, done) ->

  spy = expect.spyOn spyOn, spyFor
  routes.routeHandler routeType, routeParams

  kd.utils.wait 333, ->
    expect(spyOn[spyFor]).toHaveBeenCalled()
    done()


describe 'IDE.routes', ->

  beforeEach -> spy = null

  afterEach -> expect.restoreSpies() if spy

  describe '.routeHandler', ->

    describe 'when home, eg. /IDE', ->

      it 'should routeToLatestWorkspace', ->

        spy = expect.spyOn routes, 'routeToLatestWorkspace'
        routes.routeHandler 'home'
        expect(routes.routeToLatestWorkspace).toHaveBeenCalled()


    describe 'when machine, eg. /IDE/6075649037833338981 or /IDE/koding-vm-0', ->

      it 'should loadCollaborativeIDE if machine label is all digits which we assume it is a channel id related with a collaboration session', (done) ->

        createSpyAndAssert routes, 'loadCollaborativeIDE', 'machine', ROUTE_PARAMS.collaboration, done


      it 'should fetch machine if machine label contains chars', (done) ->

        createSpyAndAssert dataProvider, 'fetchMachine', 'machine', ROUTE_PARAMS.machine, done


      it 'should routeToMachineWorkspace if machine is fetched', (done) ->

        createSpyAndAssert routes, 'routeToMachineWorkspace', 'machine', ROUTE_PARAMS.machine, done


      it 'should routeToLatestWorkspace if no machine is fetched', (done) ->

         createSpyAndAssert routes, 'routeToLatestWorkspace', 'machine', ROUTE_PARAMS.noMachine, done


    describe 'when workspace, eg. IDE/koding-vm-0/my-workspace', ->

      it 'should fetchMachine for the given machine id', (done) ->

        createSpyAndAssert dataProvider, 'fetchMachine', 'workspace', ROUTE_PARAMS.workspace, done


      it 'should ensureDefaultWorkspace', (done) ->

        createSpyAndAssert dataProvider, 'ensureDefaultWorkspace', 'workspace', ROUTE_PARAMS.workspace, done


      it 'should routeToLatestWorkspace if there is no machine', (done) ->

        params = ROUTE_PARAMS.noMachine
        params.workspaceSlug = 'my-workspace'

        createSpyAndAssert routes, 'routeToLatestWorkspace', 'workspace', params, done


      it 'should fetchWorkspaceByMachineUId', (done) ->

        createSpyAndAssert dataProvider, 'fetchWorkspaceByMachineUId', 'workspace', ROUTE_PARAMS.workspace, done


      it 'should loadIDE if machine and workpsace is found', (done) ->

        createSpyAndAssert routes, 'loadIDE', 'workspace', ROUTE_PARAMS.workspace, done


      it 'should routeToMachineWorkspace if workspace is not found', (done) ->

        createSpyAndAssert routes, 'routeToMachineWorkspace', 'workspace', ROUTE_PARAMS.noWorkspace, done
