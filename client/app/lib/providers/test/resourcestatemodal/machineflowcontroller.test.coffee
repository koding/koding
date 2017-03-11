kd = require 'kd'
expect  = require 'expect'
constants = require 'app/providers/resourcestatemodal/constants'
MachineFlowController = require 'app/providers/resourcestatemodal/controllers/machineflowcontroller'
PageContainer = require 'app/providers/resourcestatemodal/views/pagecontainer'
StartMachinePageView = require 'app/providers/resourcestatemodal/views/machineflow/startmachinepageview'
StartMachineProgressPageView = require 'app/providers/resourcestatemodal/views/machineflow/startmachineprogresspageview'
StartMachineSuccessPageView = require 'app/providers/resourcestatemodal/views/machineflow/startmachinesuccesspageview'
StartMachineErrorPageView = require 'app/providers/resourcestatemodal/views/machineflow/startmachineerrorpageview'
StopMachineProgressPageView = require 'app/providers/resourcestatemodal/views/machineflow/stopmachineprogresspageview'
StopMachineErrorPageView = require 'app/providers/resourcestatemodal/views/machineflow/stopmachineerrorpageview'

describe 'MachineFlowController', ->

  container = null
  machineId = '1'
  anotherMachineId = '2'

  { COMPLETE_PROGRESS_VALUE } = constants

  createMachine = (state) -> { status : { state }, _id : machineId }


  beforeEach ->

    container = new PageContainer()
    container.parentIsInDom = yes


  describe '::setup', ->

    it 'requests parent container to close if start machine success page asks for that', ->

      machine = createMachine 'Running'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.prevState = 'Starting'

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'ClosingRequested', -> listener.callback()

      controller.completeProcess()
      controller.startMachineSuccessPage.emit 'ClosingRequested'

      expect(spy).toHaveBeenCalled()


  describe '::updateStatus', ->

    it 'should show error page if machine start is failed', ->

      machine = createMachine 'Starting'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Stopped', error : 'Start failed', eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachineErrorPageView).toBeTruthy()

    it 'should show error page if machine stop is failed', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Running', error : 'Stop failed', eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StopMachineErrorPageView).toBeTruthy()

    it 'should show proper page depending on incoming status if machine process failed with unexpected state', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Starting', error : 'Error!', eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachineProgressPageView).toBeTruthy()

    it 'should show success page if machine process is completed', ->

      machine = createMachine 'Starting'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Running', percentage : COMPLETE_PROGRESS_VALUE, eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachineSuccessPageView).toBeTruthy()

    it 'should show proper page depending on incoming status if machine process is completed but no success page is used for it', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Stopped', percentage : COMPLETE_PROGRESS_VALUE, eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachinePageView).toBeTruthy()

    it 'should show progress page when machine is starting', ->

      percentage = 50
      message = 'Starting VM...'
      machine = createMachine 'Starting'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Starting', percentage, message, eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachineProgressPageView).toBeTruthy()

      { progressBar, statusText } = controller.startMachineProgressPage
      expect(progressBar.bar.getWidth()).toEqual percentage
      expect(statusText.getElement().innerHTML).toEqual message

    it 'should show progress page when machine is stopping', ->

      percentage = 30
      message = 'Stopping VM...'
      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      controller.updateStatus { status : 'Stopping', percentage, message, eventId : machineId }

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StopMachineProgressPageView).toBeTruthy()

      { progressBar, statusText } = controller.stopMachineProgressPage
      expect(progressBar.bar.getWidth()).toEqual percentage
      expect(statusText.getElement().innerHTML).toEqual message

    it 'should emit ResourceBecameRunning event if machine unexpectedly became running', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'ResourceBecameRunning', -> listener.callback()

      controller.updateStatus { status : 'Running', eventId : machineId }
      expect(spy).toHaveBeenCalled()

    it 'ignores events not related to current machine', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StopMachineProgressPageView).toBeTruthy()

      controller.updateStatus { status : 'Stopped', percentage : COMPLETE_PROGRESS_VALUE, eventId : anotherMachineId }

      expect(activePane.mainView instanceof StopMachineProgressPageView).toBeTruthy()


  describe '::show', ->

    it 'should show start machine progress page for machine with Starting state', ->

      machine = createMachine 'Starting'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachineProgressPageView).toBeTruthy()

    it 'should show stop machine progress page for machine with Stopping state', ->

      machine = createMachine 'Stopping'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StopMachineProgressPageView).toBeTruthy()

    it 'should show start machine page for machine with Stopped state', ->

      machine = createMachine 'Stopped'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StartMachinePageView).toBeTruthy()

    it 'ignores unexpected machine state', ->

      machine = createMachine 'Running'
      controller = new MachineFlowController { container }, machine
      controller.setup()
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toNotExist()
