kd                    = require 'kd'
mock                  = require '../../../../mocks/mockingjay'
expect                = require 'expect'
FSFile                = require 'app/util/fs/fsfile'
FSHelper              = require 'app/util/fs/fshelper'
IDEView               = require 'ide/views/tabview/ideview'
IDEHelpers            = require '../../../lib/idehelpers'
AppController         = require 'app/appcontroller'
IDEEditorPane         = require 'ide/workspace/panes/ideeditorpane'
IDETailerPane         = require 'ide/workspace/panes/idetailerpane'
IDETerminalPane       = require 'ide/workspace/panes/ideterminalpane'
IDEDrawingPane        = require 'ide/workspace/panes/idedrawingpane'
showErrorNotification = require 'app/util/showErrorNotification'
IDEApplicationTabView = require 'ide/views/tabview/ideapplicationtabview'

ideView                     = null
showErrorNotificationSpy    = null
revertShowErrorNotification = null

initSpies = ->

  expect.spyOn IDEView.prototype, 'updateStatusBar'
  expect.spyOn IDEView.prototype, 'bindListeners'
  expect.spyOn IDEView.prototype, 'trimUntitledFileName'
  expect.spyOn IDEView.prototype, 'handlePaneRemoved'

  showErrorNotificationSpy    = expect.createSpy()
  revertShowErrorNotification = IDEView.__set__ 'showErrorNotification', showErrorNotificationSpy


getFile = ->

  path    = 'foo/path'
  machine = mock.getMockMachine()

  return FSHelper.createFileInstance { path, machine }


createEditorPane = (paneClass) ->

  file    = FSHelper.createFileInstance path: '/foo/bar'
  content = 'Foo bar baz waz here'
  options = { name: 'Foo Bar' }

  clazz      = paneClass or IDEEditorPane
  ideView    = new IDEView
  editorPane = new clazz { file, content }

  expect.spyOn(ideView.tabView, 'addPane').andCallThrough()

  pane = ideView.createPane_ editorPane, options, file

  return { ideView, editorPane, pane, file }


describe 'IDEView', ->


  beforeEach ->

    initSpies()
    ideView = new IDEView


  afterEach ->

    expect.restoreSpies()
    revertShowErrorNotification()


  describe 'constructor', ->


    it 'should be instantiated', -> expect(ideView).toBeA IDEView


    it 'should have default options set and invoke required methods', ->

      expect.spyOn IDEView.prototype, 'setHash'
      expect.spyOn IDEView.prototype, 'bindListeners'

      ideView = new IDEView
      options = ideView.getOptions()

      expect(options.tabViewClass).toBe IDEApplicationTabView
      expect(options.createNewEditor).toBe yes
      expect(options.bind).toBe 'dragover drop'
      expect(options.addSplitHandlers).toBe yes

      expect(ideView.openFiles).toEqual []
      expect(ideView.setHash).toHaveBeenCalled()
      expect(ideView.bindListeners).toHaveBeenCalled()


  describe '::createPane_', ->

    it 'should return error if missing arguments provided', ->

      expect(-> ideView.createPane_()).toThrow        /Missing argument/
      expect(-> ideView.createPane_ {}).toThrow       /Missing argument/
      expect(-> ideView.createPane_ null, {}).toThrow /Missing argument/
      expect(-> ideView.createPane_ {}, {}).toThrow   /must be an instance of KDView/


    it 'should create a KDTabPaneView and append it to ideView\'s tabView', ->

      { ideView, editorPane, pane } = createEditorPane()

      expect(ideView.tabView.addPane).toHaveBeenCalled()
      expect(pane).toBeA kd.TabPaneView
      expect(pane.view).toBe editorPane
      expect(pane.subViews.first).toBe editorPane
      expect(ideView.tabView.panes).toInclude pane
      expect(ideView.trimUntitledFileName).toHaveBeenCalledWith 'Foo Bar'
      expect(pane.tabHandle.subViews.length).toBe 1

      pane.emit 'KDObjectWillBeDestroyed'
      expect(ideView.handlePaneRemoved).toHaveBeenCalled()


    it 'should create tail icon if the view is an instance of an IDETailerPane', ->

      { ideView, editorPane, pane } = createEditorPane IDETailerPane

      { subViews } = pane.tabHandle

      expect(subViews.length).toBe 2
      expect(subViews.last).toBeA kd.CustomHTMLView
      expect(subViews.last.options.cssClass).toBe 'tail-icon'


  describe '::createTerminal', ->

    it 'should create a terminal pane and append it', ->

      app = new AppController
      app.workspaceData = { rootPath: '/root/path' }

      mock.appManager.getFrontApp.toReturnPassedParam app

      pane = ideView.createTerminal { machine: mock.getMockMachine() }

      expect(pane).toBeA kd.TabPaneView
      expect(pane.view).toBeA IDETerminalPane
      expect(pane.options.name).toBe 'Terminal'
      expect(ideView.tabView.panes).toInclude pane
      expect(pane.view.options.path).toBe '/root/path'


  describe '::createDrawingBoard', ->

    it 'should create a drawing board and append it', ->

      ideView.createDrawingBoard '123ea1'
      pane = ideView.tabView.panes.first.view

      expect(pane).toBeA IDEDrawingPane
      expect(pane.hash).toBe '123ea1'


  describe '::createEditor', ->

    it 'should create new file instance if no file is passed', ->

      fileContent    = 'foo bar content'
      dummyFileName  = 'localfile:/Untitled.txt@1452090820440'
      mountedMachine = mock.getMockMachine()
      callbackFn     = ->

      spy = expect.spyOn IDEView.prototype, 'createEditorAfterFileCheck'
      expect.spyOn(IDEView.prototype, 'getDummyFilePath').andReturn dummyFileName
      mock.appManager.getFrontApp.toReturnPassedParam { mountedMachine }

      ideView = new IDEView
      ideView.createEditor null, fileContent, callbackFn

      expect(ideView.getDummyFilePath).toHaveBeenCalled()
      expect(ideView.createEditorAfterFileCheck).toHaveBeenCalled()

      [ fileInstance, content, callback, emitChange, isReadOnly ] = spy.calls[0].arguments
      expect(fileInstance).toBeA FSFile
      expect(fileInstance.machine).toEqual mountedMachine
      expect(fileInstance.options.path).toBe dummyFileName
      expect(content).toBe fileContent
      expect(callback).toBe callbackFn
      expect(emitChange).toBe yes
      expect(isReadOnly).toBe no


    it 'should fetch permission of a file before opening it', ->

      mock.fsFile.fetchPermissions.toReturnInfo()
      ideView.createEditor file = getFile()
      expect(file.fetchPermissions).toHaveBeenCalled()


    it 'should showFileAccessDeniedError if file is not readble', ->

      expect.spyOn IDEHelpers, 'showFileAccessDeniedError'
      mock.fsFile.fetchPermissions.toReturnInfo no, no

      ideView.createEditor getFile()
      expect(IDEHelpers.showFileAccessDeniedError).toHaveBeenCalled()


    it 'should showErrorNotification if file.fetchPermissions returns error', ->

      err = message: 'Everything is something happened.'
      mock.fsFile.fetchPermissions.toReturnError err
      ideView.createEditor getFile()

      expect(showErrorNotificationSpy).toHaveBeenCalledWith err


  describe '::createEditorAfterFileCheck', ->

    it 'should create the IDEEditorPane and call createPane_ method and emit change object', ->

      uid        = mock.getMockMachine().uid
      file       = getFile()
      path       = file.path
      content    = 'foo'
      callback   = ->
      eventFlag  = no
      emitChange = yes
      isReadOnly = no
      change     = context: file: { content, path, machine: { uid } }

      createPaneSpy = expect.spyOn ideView, 'createPane_'
      emitChangeSpy = expect.spyOn ideView, 'emitChange'
      expect.spyOn ideView, 'switchToEditorTabByFile'
      ideView.once 'NewEditorPaneCreated', -> eventFlag = yes

      editorPane      = ideView.createEditorAfterFileCheck file, content, callback, emitChange, isReadOnly
      [ ep, opt, fl ] = createPaneSpy.calls.first.arguments
      [ ed, ch ]      = emitChangeSpy.calls.first.arguments

      expect(editorPane).toBeA IDEEditorPane
      expect(ep).toBe editorPane
      expect(ed).toBe editorPane
      expect(fl).toBe file
      expect(opt).toEqual { name: file.name, editor: editorPane, aceView: editorPane.aceView }
      expect(eventFlag).toBe yes
      expect(ch).toEqual change
      expect(editorPane.options.ideViewHash).toBe ideView.hash
      expect(editorPane.options.file).toBe file
      expect(editorPane.options.content).toBe content
      expect(editorPane.options.delegate).toBe ideView

      editorPane.emit 'ShowMeAsActive'
      expect(ideView.switchToEditorTabByFile).toHaveBeenCalledWith file
