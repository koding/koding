kd = require 'kd'
expect  = require 'expect'
StackFlowController = require 'app/providers/resourcestatemodal/controllers/stackflowcontroller'
PageContainer = require 'app/providers/resourcestatemodal/views/pagecontainer'

describe 'StackFlowController', ->

  container = new PageContainer()
  stackTemplate = { description : 'Test template', template : { rawContent : 'test' } }

  describe '::show', ->

    it 'should call instructions controller if stack status is NotInitialized', ->

      machine = { status : { state : 'NotInitialized' } }
      stack   = { status : { state : 'NotInitialized' } }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.instructions, 'show'

      controller.show()
      expect(spy).toHaveBeenCalled()

    it 'should call build stack controller if stack status is Building', ->

      machine = { status : { state : 'Building' } }
      stack   = { status : { state : 'Building' } }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.buildStack, 'show'

      controller.show()
      expect(spy).toHaveBeenCalled()

  describe '::setup', ->

    it 'should call credentials controller if instructions controller asks for that', ->

      machine = { status : { state : 'NotInitialized' } }
      stack   = { status : { state : 'NotInitialized' } }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.credentials, 'show'

      controller.instructions.emit 'NextPageRequested'
      expect(spy).toHaveBeenCalled()

    it 'should call instructions controller if credentials controller asks for that', ->

      machine = { status : { state : 'NotInitialized' } }
      stack   = { status : { state : 'NotInitialized' } }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.instructions, 'show'

      controller.credentials.emit 'InstructionsRequested'
      expect(spy).toHaveBeenCalled()

    it 'should show credentials controller if build stack controller asks for that', ->

      machine = { status : { state : 'NotInitialized' } }
      stack   = { status : { state : 'NotInitialized' } }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.credentials, 'show'

      controller.buildStack.emit 'CredentialsRequested'
      expect(spy).toHaveBeenCalled()


  describe '::updateStatus', ->

    it 'should call build stack controller to show event error', ->

      machine = { status : { state : 'Building' } }
      stack   = { status : { state : 'Building' }, _id : '1' }
      error   = 'Build error'

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.buildStack, 'showError'

      controller.updateStatus { eventId : '1', error }
      expect(spy).toHaveBeenCalledWith error

    it 'should call build stack controller to show build progress', ->

      machine = { status : { state : 'Building' } }
      stack   = { status : { state : 'Building' }, _id : '1' }

      percentage = 50
      message    = 'Checking remote VMs...'

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller.buildStack, 'updateBuildProgress'

      controller.updateStatus { eventId : '1', percentage, message }
      expect(spy).toHaveBeenCalledWith percentage, message


    it 'should emit ResourceBecameRunning if event status is Running', ->

      machine = { status : { state : 'Building' } }
      stack   = { status : { state : 'Building' }, _id : '1' }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      spy = expect.spyOn controller, 'emit'

      controller.updateStatus { eventId : '1', status : 'Running' }
      expect(spy.calls.length).toEqual 1
      expect(spy.calls[0].arguments[0]).toEqual 'ResourceBecameRunning'

    it 'should not handle event with another stack id', ->

      machine = { status : { state : 'NotInitialized' } }
      stack   = { status : { state : 'NotInitialized' }, _id : '1' }

      controller = new StackFlowController { container }, { machine, stack }
      controller.setup stackTemplate

      controller.updateStatus { eventId : '2', percentage : 50 }

      activePane = container.getActivePane()
      expect(activePane).toNotExist()
