kd      = require 'kd'
mock    = require '../../mocks/mockingjay'
expect  = require 'expect'

ComputeHelpers            = require 'app/providers/computehelpers'
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
EnvironmentListItem       = require 'app/environment/environmentlistitem'
EnvironmentListController = require 'app/environment/environmentlistcontroller'


describe 'EnvironmentListController', ->

  afterEach -> expect.restoreSpies()

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new EnvironmentListController

      { wrapper, itemClass, scrollView, fetcherMethod } = listController.getOptions()

      expect(wrapper).toBeFalsy()
      expect(itemClass).toBe EnvironmentListItem
      expect(scrollView).toBeFalsy()
      expect(fetcherMethod).toBeA 'function'


  describe '::bindEvents', ->

    it 'should listen RenderStacks event and call loadItems', ->

      expect.spyOn EnvironmentListController.prototype, 'loadItems'

      listController = new EnvironmentListController

      kd.singletons.computeController.emit 'RenderStacks'

      expect(listController.loadItems).toHaveBeenCalled()

    it 'should handle StackReinitRequested event', ->

      listController = new EnvironmentListController
      listView       = listController.getListView()
      item           = { getData : kd.noop }
      spy            = expect.spyOn listController, 'handleStackReinitRequest'

      listView.emit 'ItemAction', { action : 'StackReinitRequested', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should handle StackDeleteRequested event', ->

      listController = new EnvironmentListController
      listView       = listController.getListView()
      item           = { getData : kd.noop }
      spy            = expect.spyOn listController, 'handleStackDeleteRequest'

      listView.emit 'ItemAction', { action : 'StackDeleteRequested', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should handle NewMachineRequest event', ->

      listController = new EnvironmentListController
      listView       = listController.getListView()
      item           = 'softlayer'
      spy            = expect.spyOn listController, 'handleNewMachineRequest'

      listView.emit 'ItemAction', { action : 'NewMachineRequest', item }

      expect(spy).toHaveBeenCalledWith item


  describe '::handleNewMachineRequest', ->

    it 'should call handleNewMachineRequest of ComputeHelpers with given provider', ->

      provider          = 'softlayer'
      isMachineCreated  = yes

      spy = expect.spyOn(ComputeHelpers, 'handleNewMachineRequest').andCall (provider, callback) ->
        callback isMachineCreated

      listController = new EnvironmentListController
      listView       = listController.getListView()
      emitSpy        = expect.spyOn listView, 'emit'

      listController.handleNewMachineRequest provider

      expect(spy).toHaveBeenCalled()
      expect(emitSpy.calls.first.arguments[0]).toEqual 'ModalDestroyRequested'
      expect(emitSpy.calls.first.arguments[1]).toBe not isMachineCreated


  describe '::handleStackDeleteRequest', ->

    it 'should reset all stacks if there is no error', ->

      { computeController } = kd.singletons

      expect.spyOn(computeController, 'destroyStack').andCall (stack, callback) -> callback null

      item            = { getData : kd.noop }
      spy             = expect.spyOn computeController, 'reset'
      listController  = new EnvironmentListController

      listController.handleStackDeleteRequest item

      expect(spy).toHaveBeenCalled()

    it 'should not reset all stacks if any error', ->

      { computeController } = kd.singletons

      expect.spyOn(computeController, 'destroyStack').andCall (stack, callback) -> callback new Error 'error!'

      item            = { getData : kd.noop }
      spy             = expect.spyOn computeController, 'reset'
      listController  = new EnvironmentListController

      listController.handleStackDeleteRequest item

      expect(spy).toNotHaveBeenCalled()


  describe '::handleStackReinitRequest', ->

    it 'should hide loader when reinit stack process is completed', ->

      { computeController } = kd.singletons

      expect.spyOn(computeController, 'reinitStack').andCall (stack, callback) -> callback()

      listController  = new EnvironmentListController
      listView        = listController.getListView()

      item            =
        getData       : kd.noop
        reinitButton  :
          hideLoader  : kd.noop

      spy     = expect.spyOn item.reinitButton, 'hideLoader'
      emitSpy = expect.spyOn listView, 'emit'

      listController.handleStackReinitRequest item
      computeController.emit 'RenderStacks'

      expect(spy).toHaveBeenCalled()
      expect(emitSpy.calls.first.arguments[0]).toEqual 'ModalDestroyRequested'
      expect(emitSpy.calls.first.arguments[1]).toBe yes
      expect(emitSpy.calls.first.arguments[2]).toBe yes


  describe '::addListItems', ->

    it 'should add multi-stack css class to view', ->

      expect.spyOn EnvironmentListController.prototype, 'instantiateListItems'
      listController  = new EnvironmentListController
      view            = listController.getView()
      stacks          = []

      stacks.push mock.getMockComputeStack()
      stacks.push mock.getMockComputeStack()

      listController.addListItems stacks

      expect(view.hasClass 'multi-stack').toBeTruthy()
