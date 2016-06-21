kd = require 'kd'
expect  = require 'expect'
ResourceStateController = require 'app/providers/resourcestatemodal/controllers/resourcestatecontroller'
NoStackPageView = require 'app/providers/resourcestatemodal/views/nostackpageview'
StackFlowController = require 'app/providers/resourcestatemodal/controllers/stackflowcontroller'
MachineFlowController = require 'app/providers/resourcestatemodal/controllers/machineflowcontroller'

describe 'ResourceStateController', ->

  container = new kd.View()

  describe 'constructor', ->

    it 'should add page container view to a parent container', ->

      controller = new ResourceStateController { container }

      { pageContainer } = controller
      expect(pageContainer).toExist()
      expect(container.subViews.indexOf pageContainer).toBeGreaterThan -1

    it 'should show loader if machine is passed', ->

      machine = { status : { state : 'Stopped' } }
      controller = new ResourceStateController { container }, machine

      { pageContainer } = controller
      activePane = pageContainer.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView.hasClass 'loader-container').toBeTruthy()

    it 'should show NoStackPageView if machine is not passed', ->

      controller = new ResourceStateController { container }

      { pageContainer } = controller
      activePane = pageContainer.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof NoStackPageView).toBeTruthy()


  describe '::setup', ->

    it 'should set MachineFlowController as a current flow if stack status is Initialized', ->

      machine = { status : { state : 'Starting' } }
      stack = { status : { state : 'Initialized' } }

      controller = new ResourceStateController { container }, machine
      controller.setup stack

      expect(controller.currentFlow instanceof MachineFlowController).toBeTruthy()

    it 'should set StackFlowController as a current flow if stack status is not Initialized', ->

      machine = { status : { state : 'NotInitialized' } }
      stack = { status : { state : 'NotInitialized' } }

      controller = new ResourceStateController { container }, machine
      controller.setup stack

      expect(controller.currentFlow instanceof StackFlowController).toBeTruthy()
