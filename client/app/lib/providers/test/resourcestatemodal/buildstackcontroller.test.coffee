kd = require 'kd'
expect  = require 'expect'
constants = require 'app/providers/resourcestatemodal/constants'
BuildStackController = require 'app/providers/resourcestatemodal/controllers/buildstackcontroller'
PageContainer = require 'app/providers/resourcestatemodal/views/pagecontainer'
BuildStackPageView = require 'app/providers/resourcestatemodal/views/stackflow/buildstackpageview'
BuildStackErrorPageView = require 'app/providers/resourcestatemodal/views/stackflow/buildstackerrorpageview'
BuildStackSuccessPageView = require 'app/providers/resourcestatemodal/views/stackflow/buildstacksuccesspageview'
BuildStackLogsPageView = require 'app/providers/resourcestatemodal/views/stackflow/buildstacklogspageview'

describe 'BuildStackController', ->

  container     = null
  machine       = { status : { state : 'Building' } }
  stack         = { title : 'Test stack', status : { state : 'Building' } }
  stackTemplate =
    description : 'Test template'
    template    : { rawContent : 'test' }
    config      : { buildDuration : 0.1 }

  beforeEach ->

    container = new PageContainer()
    container.parentIsInDom = yes

  describe 'constructor', ->

    it 'requests credentials page from parent controller if error page asks for that', ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'CredentialsRequested', -> listener.callback()

      controller.errorPage.emit 'CredentialsRequested'
      expect(spy).toHaveBeenCalled()

    it 'requests stack rebuild from parent controller if error page asks for that', (done) ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'RebuildRequested', -> listener.callback()

      kd.utils.defer ->
        controller.show()
        controller.errorPage.emit 'RebuildRequested'

        expect(spy).toHaveBeenCalled()
        done()

    it 'requests closing from parent controller if success page asks for that', ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'ClosingRequested', -> listener.callback()

      controller.successPage.emit 'ClosingRequested'
      expect(spy).toHaveBeenCalled()

    it 'requests closing from parent controller if logs page asks for that', ->

      controller = new BuildStackController { container }, { machine, stack }

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'ClosingRequested', -> listener.callback()

      controller.logsPage.emit 'ClosingRequested'
      expect(spy).toHaveBeenCalled()


  describe '::updateBuildProgress', ->

    it 'should show build progress percentage and specified message', (done) ->

      { MAX_BUILD_PROGRESS_VALUE, COMPLETE_PROGRESS_VALUE } = constants

      percentage = 40
      message = 'Checking VMs...'

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      kd.utils.defer ->
        controller.updateBuildProgress percentage, message

        percentage = percentage * MAX_BUILD_PROGRESS_VALUE / COMPLETE_PROGRESS_VALUE
        { buildStackPage : { progressBar, statusText } } = controller

        expect(progressBar.bar.getWidth()).toEqual percentage
        expect(statusText.getElement().innerHTML).toEqual message

        done()


  describe '::completeBuildProcess', ->

    it 'should start timer of post build progress', (done) ->

      { COMPLETE_PROGRESS_VALUE } = constants

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      kd.utils.defer ->
        controller.show()

        expect(controller.postBuildTimer).toNotExist()
        controller.completeBuildProcess()

        expect(controller.postBuildTimer).toExist()

        kd.utils.wait stackTemplate.config.buildDuration * 1000 + 10, ->
          { buildStackPage : { progressBar } } = controller
          expect(progressBar.bar.getWidth()).toEqual COMPLETE_PROGRESS_VALUE

          done()


  describe '::completePostBuildProcess', ->

    it 'should show success page and stop post build timer and timeout checker when build is done', (done) ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      kd.utils.defer ->
        controller.show()

        expect(controller.postBuildTimer).toNotExist()
        expect(controller.timeoutChecker).toNotExist()

        controller.completeBuildProcess()

        kd.utils.wait 10, ->
          expect(controller.postBuildTimer.timer).toExist()
          expect(controller.timeoutChecker.timer).toExist()
          controller.buildStackPage.emit 'BuildDone'

          expect(controller.postBuildTimer.timer).toNotExist()
          expect(controller.timeoutChecker.timer).toNotExist()

          activePane = container.getActivePane()
          expect(activePane).toExist()
          expect(activePane.mainView instanceof BuildStackSuccessPageView).toBeTruthy()

          done()


  describe '::showError', ->

    it 'should show error page', (done) ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }
      kd.utils.defer ->
        controller.show()
        controller.showError 'Error!'

        activePane = container.getActivePane()
        expect(activePane).toExist()
        expect(activePane.mainView instanceof BuildStackErrorPageView).toBeTruthy()

        done()


  describe '::showLogs', ->

    it 'should show logs page if success page asks for that', (done) ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      kd.utils.defer ->
        controller.successPage.emit 'LogsRequested'

        activePane = container.getActivePane()
        expect(activePane).toExist()
        expect(activePane.mainView instanceof BuildStackLogsPageView).toBeTruthy()

        done()


  describe '::show', ->

    it 'should show build page by default', (done) ->

      controller = new BuildStackController { container }, { machine, stack, stackTemplate }

      kd.utils.defer ->
        controller.show()

        activePane = container.getActivePane()
        expect(activePane).toExist()
        expect(activePane.mainView instanceof BuildStackPageView).toBeTruthy()

        done()
