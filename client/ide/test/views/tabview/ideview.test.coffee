kd                    = require 'kd'
mock                  = require '../../../../mocks/mockingjay'
nick                  = require 'app/util/nick'
expect                = require 'expect'
IDEAce                = require 'ide/views/ace/ideace'
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


getFile = (path = 'foo/path') ->

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


    it 'should listen for EditorIsReady event and handle the cases', ->

      obj            = callback: ->
      file           = getFile()
      content        = 'foo bar'
      cursor         = { row: 1, column: 2 }
      fakeAce        = new IDEAce
      fakeAce.editor =
        scrollToRow  : ->
        setReadOnly  : ->

      expect.spyOn obj, 'callback'

      editorPane = ideView.createEditorAfterFileCheck file, content, obj.callback, yes, yes

      expect.spyOn(editorPane, 'getAce').andReturn fakeAce
      expect.spyOn editorPane, 'goToLine'
      expect.spyOn fakeAce.editor, 'scrollToRow'
      expect.spyOn IDEHelpers, 'showFileReadOnlyNotification'
      expect.spyOn editorPane, 'makeReadOnly'
      spy = expect.spyOn kd.singletons.appManager, 'tell'

      editorPane.emit 'EditorIsReady'

      expect(fakeAce.editor.scrollToRow).toHaveBeenCalledWith 0
      expect(editorPane.goToLine).toHaveBeenCalledWith 1
      expect(IDEHelpers.showFileReadOnlyNotification).toHaveBeenCalled()
      expect(editorPane.makeReadOnly).toHaveBeenCalled()
      expect(obj.callback).toHaveBeenCalledWith editorPane

      fakeAce.emit 'ace.change.cursor', cursor
      [ appName, methodName, paneType, data ] = spy.calls[0].arguments

      expect(appName).toBe 'IDE'
      expect(methodName).toBe 'updateStatusBar'
      expect(paneType).toBe 'editor'
      expect(data.cursor).toBe cursor
      expect(data.file).toBe file

      fakeAce.emit 'FindAndReplaceViewRequested', yes
      [ appName_, methodName_, inReplaceMode ] = spy.calls[1].arguments

      expect(appName_).toBe 'IDE'
      expect(methodName_).toBe 'showFindReplaceView'
      expect(inReplaceMode).toBe yes


  describe '::emitChange', ->

    it 'should create a change object and emit it', ->

      hash     = '1F9B0F7B'
      paneType = 'FooPane'
      pane     = { hash, options: { paneType } }
      change   = { context: foo: 'bar' }

      ideView.on 'ChangeHappened', (change) ->
        expect(change.type).toBe  'MyChangeType'
        expect(change.origin).toBe nick()
        expect(change.context.paneType).toBe paneType
        expect(change.context.paneHash).toBe hash
        expect(change.context.ideViewHash).toBe ideView.hash

      ideView.emitChange pane, change, 'MyChangeType'


    it 'should add file to change object if change type is PaneRemoved or TabChanged', ->

      file = getFile()
      pane = { file }

      for type in [ 'PaneRemoved', 'TabChanged' ]
        ideView.once 'ChangeHappened', (change) ->
          expect(change.type).toBe type
          expect(change.context.file.path).toBe file.path

        ideView.emitChange pane, null, type


  describe '::openFile', ->

    it 'should switchToEditorTabByFile if the same file is already opened', ->

      fooFile   = getFile 'foo/file/path'
      barFile   = getFile 'bar/file/path'
      callbacks =
        foo     : ->
        bar     : ->

      expect.spyOn callbacks, 'foo'
      expect.spyOn callbacks, 'bar'
      expect.spyOn ideView, 'switchToEditorTabByFile'

      ideView.openFiles.push fooFile, barFile

      ideView.openFile fooFile, 'foo', callbacks.foo

      expect(ideView.switchToEditorTabByFile).toHaveBeenCalledWith fooFile
      expect(callbacks.foo).toHaveBeenCalled()

      ideView.openFile barFile, 'bar', callbacks.bar

      expect(ideView.switchToEditorTabByFile).toHaveBeenCalledWith barFile
      expect(callbacks.bar).toHaveBeenCalled()


    it 'should createEditor for the given file', ->

      file = getFile 'baz/waz'
      spy  = expect.spyOn(ideView, 'createEditor').andCall (f, c, k, e) -> k new kd.TabPaneView

      ideView.openFile file

      expect(ideView.createEditor).toHaveBeenCalled()
      expect(spy.calls.first.arguments.first).toBe file
      expect(ideView.openFiles.indexOf(file)).toBeGreaterThan -1
