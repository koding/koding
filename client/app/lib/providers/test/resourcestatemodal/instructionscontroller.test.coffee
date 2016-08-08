kd = require 'kd'
expect  = require 'expect'
InstructionsController = require 'app/providers/resourcestatemodal/controllers/instructionscontroller'
PageContainer = require 'app/providers/resourcestatemodal/views/pagecontainer'
ReadmePageView = require 'app/providers/resourcestatemodal/views/stackflow/readmepageview'
StackTemplatePageView = require 'app/providers/resourcestatemodal/views/stackflow/stacktemplatepageview'

describe 'InstructionsController', ->

  stackTemplate = { description : 'Test template', template : { rawContent : 'test' } }
  stack = { title : 'Test template stack' }
  container = null

  beforeEach ->

    container = new PageContainer()


  describe 'constructor', ->

    it 'should show stack template page if readme page requests it', ->

      controller = new InstructionsController { container }, { stackTemplate, stack }
      controller.readmePage.emit 'StackTemplateRequested'

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof StackTemplatePageView).toBeTruthy()

    it 'should show readme page if stack template page requests it', ->

      controller = new InstructionsController { container }, { stackTemplate, stack }
      controller.readmePage.emit 'StackTemplateRequested'
      controller.stackTemplatePage.emit 'ReadmeRequested'

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof ReadmePageView).toBeTruthy()

    it 'requests next page from parent controller if readme or stack template pages ask for that', ->

      controller = new InstructionsController { container }, { stackTemplate, stack }

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'NextPageRequested', -> listener.callback()

      controller.readmePage.emit 'NextPageRequested'
      expect(spy).toHaveBeenCalled()

      spy.restore()
      controller.stackTemplatePage.emit 'NextPageRequested'
      expect(spy).toHaveBeenCalled()


  describe '::show', ->

    it 'should show readme page by default', ->

      controller = new InstructionsController { container }, { stackTemplate, stack }
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof ReadmePageView).toBeTruthy()
