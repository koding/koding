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
showError = require 'app/util/showError'
IDEApplicationTabView = require 'ide/views/tabview/ideapplicationtabview'

ideView                     = null
handlePaneRemovedSpy        = null
showErrorSpy    = null
revertShowError = null


initSpies = ->

  expect.spyOn IDEView.prototype, 'updateStatusBar'
  expect.spyOn IDEView.prototype, 'trimUntitledFileName'
  handlePaneRemovedSpy = expect.spyOn IDEView.prototype, 'handlePaneRemoved'

  showErrorSpy    = expect.createSpy()
  revertShowError = IDEView.__set__ 'showError', showErrorSpy


createFile = (path = 'foo/path') ->

  machine = mock.getMockMachine()
  return FSHelper.createFileInstance { path, machine }


createEditorPane = (paneClass) ->

  file    = FSHelper.createFileInstance { path: '/foo/bar' }
  content = 'Foo bar baz waz here'
  options = { name: 'Foo Bar' }

  clazz      = paneClass or IDEEditorPane
  ideView    = new IDEView
  editorPane = new clazz { file, content }

  expect.spyOn(ideView.tabView, 'addPane').andCallThrough()

  pane = ideView.createPane_ editorPane, options, file

  return { ideView, editorPane, pane, file }


createTerminalPane = (options = {}) ->

  app = new AppController { name: "FooApp#{Date.now()}" }

  mock.appManager.getFrontApp.toReturnPassedParam app

  options.machine = mock.getMockMachine()
  pane = ideView.createTerminal options

  return pane


describe 'IDEView', ->


  beforeEach ->

    initSpies()
    ideView = new IDEView


  afterEach ->

    expect.restoreSpies()
    revertShowError()


  describe 'constructor', ->


    it 'should be instantiated', -> expect(ideView).toBeA IDEView


    it 'should have default options set and invoke required methods', ->

      expect.spyOn IDEView.prototype, 'setHash'

      ideView = new IDEView
      options = ideView.getOptions()

      expect(options.tabViewClass).toBe IDEApplicationTabView
      expect(options.createNewEditor).toBe yes
      expect(options.bind).toBe 'dragover drop'
      expect(options.addSplitHandlers).toBe yes

      expect(ideView.openFiles).toEqual []
      expect(ideView.setHash).toHaveBeenCalled()


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

      pane = createTerminalPane()

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
      ideView.createEditor file = createFile()
      expect(file.fetchPermissions).toHaveBeenCalled()


    it 'should showFileAccessDeniedError if file is not readble', ->

      expect.spyOn IDEHelpers, 'showFileAccessDeniedError'
      mock.fsFile.fetchPermissions.toReturnInfo no, no

      ideView.createEditor createFile()
      expect(IDEHelpers.showFileAccessDeniedError).toHaveBeenCalled()


    it 'should showError if file.fetchPermissions returns error', ->

      err = { message: 'Everything is something happened.' }
      mock.fsFile.fetchPermissions.toReturnError err
      ideView.createEditor createFile()

      expect(showErrorSpy).toHaveBeenCalledWith err


  describe '::createEditorAfterFileCheck', ->

    it 'should create the IDEEditorPane and call createPane_ method and emit change object', ->

      uid           = mock.getMockMachine().uid
      file          = createFile()
      path          = file.path
      content       = 'foo'
      callback      = ->
      eventFlag     = no
      emitChange    = yes
      isReadOnly    = no
      isActivePane  = yes
      change        = { context: { file: { content, path, machine: { uid } } } }

      createPaneSpy = expect.spyOn ideView, 'createPane_'
      emitChangeSpy = expect.spyOn ideView, 'emitChange'
      expect.spyOn ideView, 'switchToEditorTabByFile'
      ideView.once 'NewEditorPaneCreated', -> eventFlag = yes

      editorPane      = ideView.createEditorAfterFileCheck file, content, callback, emitChange, isReadOnly, isActivePane
      [ ep, opt, fl ] = createPaneSpy.calls.first.arguments
      [ ed, ch ]      = emitChangeSpy.calls.first.arguments

      expect(editorPane).toBeA IDEEditorPane
      expect(ep).toBe editorPane
      expect(ed).toBe editorPane
      expect(fl).toBe file
      expect(opt).toEqual {
        name          : file.name,
        editor        : editorPane,
        aceView       : editorPane.aceView,
        isActivePane  : isActivePane
      }
      expect(eventFlag).toBe yes
      expect(ch).toEqual change
      expect(editorPane.options.ideViewHash).toBe ideView.hash
      expect(editorPane.options.file).toBe file
      expect(editorPane.options.content).toBe content
      expect(editorPane.options.delegate).toBe ideView

      editorPane.emit 'ShowMeAsActive'
      expect(ideView.switchToEditorTabByFile).toHaveBeenCalledWith file


    it 'should listen for EditorIsReady event and handle the cases', ->

      obj            = { callback: -> }
      file           = createFile()
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
      change   = { context: { foo: 'bar' } }

      ideView.on 'ChangeHappened', (change) ->
        expect(change.type).toBe  'MyChangeType'
        expect(change.origin).toBe nick()
        expect(change.context.paneType).toBe paneType
        expect(change.context.paneHash).toBe hash
        expect(change.context.ideViewHash).toBe ideView.hash

      ideView.emitChange pane, change, 'MyChangeType'


    it 'should add file to change object if change type is PaneRemoved or TabChanged', ->

      file = createFile()
      pane = { file }

      for type in [ 'PaneRemoved', 'TabChanged' ]
        ideView.once 'ChangeHappened', (change) ->
          expect(change.type).toBe type
          expect(change.context.file.path).toBe file.path

        ideView.emitChange pane, null, type


  describe '::openFile', ->

    it 'should switchToEditorTabByFile if the same file is already opened', ->

      fooFile   = createFile 'foo/file/path'
      barFile   = createFile 'bar/file/path'
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

      file = createFile 'baz/waz'
      spy  = expect.spyOn(ideView, 'createEditor').andCall (f, c, k, e) -> k new kd.TabPaneView

      ideView.openFile file

      expect(ideView.createEditor).toHaveBeenCalled()
      expect(spy.calls.first.arguments.first).toBe file
      expect(ideView.openFiles.indexOf(file)).toBeGreaterThan -1


  describe '::switchToEditorTabByFile', ->

    it 'should check tabView panes and call tabView.showPaneByIndex', ->

      pane1 = new kd.TabPaneView {}, file1 = createFile '/foo'
      pane2 = new kd.TabPaneView {}, file2 = createFile '/bar'
      pane3 = new kd.TabPaneView {}, file3 = createFile '/baz'

      ideView.tabView.panes.push pane1, pane2, pane3

      expect.spyOn ideView.tabView, 'showPaneByIndex'

      ideView.switchToEditorTabByFile file2
      expect(ideView.tabView.showPaneByIndex).toHaveBeenCalledWith 1

      ideView.switchToEditorTabByFile file3
      expect(ideView.tabView.showPaneByIndex).toHaveBeenCalledWith 2


  describe '::showView', ->

    it 'should call createPane_', ->

      view1 = new kd.View
      view2 = new kd.View
      spy   = expect.spyOn ideView, 'createPane_'

      ideView.showView view1

      expect(ideView.createPane_).toHaveBeenCalled()
      expect(spy.calls.first.arguments.first).toBe view1
      expect(spy.calls.first.arguments.last).toEqual { name: 'Search Result' }

      ideView.showView view2, 'My Pane'
      expect(spy.calls.last.arguments.first).toBe view2
      expect(spy.calls.last.arguments.last).toEqual { name: 'My Pane' }


  describe '::getActivePaneView', ->

    it 'should return null if there is no getActivePane', ->

      view = new kd.View
      spy  = expect.spyOn(ideView.tabView, 'getActivePane').andReturn { view }

      returnView = ideView.getActivePaneView()

      expect(ideView.tabView.getActivePane).toHaveBeenCalled()
      expect(returnView).toBe view

      spy.restore()

      expect.spyOn(ideView.tabView, 'getActivePane').andReturn null

      returnView = ideView.getActivePaneView()

      expect(ideView.tabView.getActivePane).toHaveBeenCalled()
      expect(returnView).toBe undefined


  describe '::click', ->

    it 'should call super and do extra things', ->

      expect.spyOn IDEView.__super__, 'click'
      spy = expect.spyOn kd.singletons.appManager, 'tell'
      ideView.click()

      expect(IDEView.__super__.click).toHaveBeenCalled()
      expect(ideView.updateStatusBar).toHaveBeenCalled()

      [ appName, methodName, arg ] = spy.calls.first.arguments
      [ appName_, methodName_ ]    = spy.calls.last.arguments

      expect(appName).toBe  'IDE'
      expect(appName_).toBe 'IDE'

      expect(methodName).toBe  'setActiveTabView'
      expect(methodName_).toBe 'setFindAndReplaceViewDelegate'

      expect(arg).toBe ideView.tabView

      ideView.handlePaneRemoved {}


  describe '::handlePaneRemoved', ->

    it 'should remove pane and emit event and a change event', ->

      handlePaneRemovedSpy.restore()

      file1     = createFile 'your/file'
      file2     = createFile 'my/file'
      pane      = new kd.TabPaneView {}, file2
      pane.view = new kd.View

      expect.spyOn ideView, 'emit'
      spy = expect.spyOn ideView, 'emitChange'
      ideView.openFiles.push file1, file2

      ideView.handlePaneRemoved pane

      [ view, change, eventName ] = spy.calls.first.arguments

      expect(ideView.emit).toHaveBeenCalledWith 'PaneRemoved', pane
      expect(view).toBe pane.view
      expect(change.context).toExist()
      expect(eventName).toBe 'PaneRemoved'
      expect(ideView.openFiles.indexOf(file2)).toBe -1


  describe '::handleWebtermCreated', ->

    it 'should bind click event, emit event and update title', ->

      uid              = mock.getMockMachine().uid
      pane             = createTerminalPane()
      session          = 'foo1bar2'
      pane.view.remote = { session }
      tabHandle        = ideView.tabView.getHandleByPane pane

      expect.spyOn ideView,   'click'
      expect.spyOn ideView,   'emit'
      expect.spyOn tabHandle, 'setTitle'
      spy = expect.spyOn ideView, 'emitChange'

      ideView.handleWebtermCreated pane
      pane.view.webtermView.emit 'click'

      expect(ideView.emit).toHaveBeenCalledWith 'UpdateWorkspaceSnapshot'
      expect(tabHandle.setTitle).toHaveBeenCalledWith 'foo1bar2'
      expect(ideView.click).toHaveBeenCalled()

      [ terminalPane, change ] = spy.calls.first.arguments

      expect(terminalPane).toBe pane.view
      expect(change).toEqual { context: { session, machine: { uid } } }


  describe '::handleTabMoved', ->

    it 'should call updateAceViewDelegate of the view and emitChange', ->

      { editorPane }  = createEditorPane()
      params          =
        view          : editorPane
        tabView       : { parent: { hash: '111' } }
        targetTabView : { parent: { hash: '222' } }
      expectedChange  =
        context       :
          originIDEViewHash : '111'
          targetIDEViewHash : '222'

      expect.spyOn params.view, 'updateAceViewDelegate'
      spy = expect.spyOn ideView, 'emitChange'

      ideView.handleTabMoved params

      expect(params.view.updateAceViewDelegate).toHaveBeenCalledWith params.targetTabView.parent

      [ view, change, action ] = spy.calls.first.arguments

      expect(view).toBe      params.view
      expect(action).toBe    'IDETabMoved'
      expect(change).toEqual expectedChange


  describe '::handleSplitViewCreated', ->

    it 'should emitChange', ->

      direction      = 'vertical'
      newIdeView     = new IDEView
      params         = { ideView, newIdeView, direction }
      expectedChange =
        context          :
          ideViewHash    : ideView.hash
          newIdeViewHash : newIdeView.hash
          direction      : direction

      spy = expect.spyOn ideView, 'emitChange'

      ideView.handleSplitViewCreated params

      expect(ideView.emitChange).toHaveBeenCalled()
      [ newIV, change, changeName ] = spy.calls.first.arguments

      expect(newIV).toBe      newIdeView
      expect(change).toEqual  expectedChange
      expect(changeName).toBe 'NewSplitViewCreated'


    it 'should toggleFullscreen, collapseSidebar and toggleSidebar if ideApp isFullScreen', ->

      { mainView, appManager } = kd.singletons
      params = { ideView, newIdeView: new IDEView, direction: 'horizontal' }

      expect.spyOn ideView, 'emitChange'
      expect.spyOn ideView, 'toggleFullscreen'
      expect.spyOn appManager, 'tell'
      expect.spyOn mainView, 'toggleSidebar'

      ideView.isFullScreen = yes
      ideView.handleSplitViewCreated params

      expect(appManager.tell).toHaveBeenCalledWith 'IDE', 'collapseSidebar'
      expect(mainView.toggleSidebar).toHaveBeenCalled()
      expect(ideView.toggleFullscreen).toHaveBeenCalled()


  describe '::handleSplitViewMerged', ->

    it 'should emitChange', ->

      targetIdeView  = ideView
      ideViewHash    = '1223334444'
      params         = { ideViewHash, targetIdeView }
      expectedChange = { context: { ideViewHash } }

      spy = expect.spyOn ideView, 'emitChange'

      ideView.handleSplitViewMerged params

      [ tiv, change, changeName ] = spy.calls.first.arguments

      expect(tiv).toBe targetIdeView
      expect(change).toEqual expectedChange
      expect(changeName).toBe 'SplitViewMerged'


  describe '::setHash', ->

    it 'should set given hash', ->

      ideView.setHash 1
      expect(ideView.hash).toBe 1


    it 'should generate a new hash', ->

      hash = '1a2b3c4d'
      generatePasswordSpy = expect.createSpy().andReturn hash
      revertGeneratePassword = IDEView.__set__ 'generatePassword', generatePasswordSpy

      ideView.setHash()
      expect(generatePasswordSpy).toHaveBeenCalled()
      expect(ideView.hash).toBe hash

      revertGeneratePassword()


  describe '::renameTerminal', ->

    it 'should setSession, setTitle and fetchTerminalSessions', ->

      spy      = expect.createSpy()
      pane     = createTerminalPane()
      machine  = mock.getMockMachine()
      newTitle = 'New Title'
      handle   = ideView.tabView.getHandleByPane pane

      expect.spyOn pane.view, 'setSession'
      expect.spyOn handle, 'setTitle'
      expect.spyOn(machine, 'getBaseKite').andReturn { fetchTerminalSessions: spy }

      ideView.renameTerminal pane, machine, newTitle

      expect(pane.view.setSession).toHaveBeenCalledWith newTitle
      expect(handle.setTitle).toHaveBeenCalledWith newTitle
      expect(machine.getBaseKite).toHaveBeenCalled()
      expect(spy).toHaveBeenCalled()
