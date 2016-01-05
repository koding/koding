kd                    = require 'kd'
mock                  = require '../../../../mocks/mockingjay'
expect                = require 'expect'
FSFile                = require 'app/util/fs/fsfile'
FSHelper              = require 'app/util/fs/fshelper'
IDEView               = require 'ide/views/tabview/ideview'
AppController         = require 'app/appcontroller'
IDEEditorPane         = require 'ide/workspace/panes/ideeditorpane'
IDETailerPane         = require 'ide/workspace/panes/idetailerpane'
IDETerminalPane       = require 'ide/workspace/panes/ideterminalpane'
IDEApplicationTabView = require 'ide/views/tabview/ideapplicationtabview'

ideView = null


initSpies = ->

  expect.spyOn IDEView.prototype, 'updateStatusBar'
  expect.spyOn IDEView.prototype, 'bindListeners'
  expect.spyOn IDEView.prototype, 'trimUntitledFileName'
  expect.spyOn IDEView.prototype, 'handlePaneRemoved'


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


  afterEach -> expect.restoreSpies()


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
      expect(pane.view.options.path).toBe '/root/path'
