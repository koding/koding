debug = (require 'debug') 'nse:stackeditor'

kd = require 'kd'
bowser = require 'bowser'
Encoder = require 'htmlencode'

Events = require '../events'

FlexSplit = require './flexsplit'
FlexSplitStorage = require './flexsplit/storage'
AppStorageAdapter = require './adapters/appstorageadapter'

Toolbar = require './toolbar'
Editor = require './editor'
Statusbar = require './statusbar'
SideView = require './sideview'

LogsController = require '../controllers/logs'
EditorController = require '../controllers/editor'
VariablesController = require '../controllers/variables'
CredentialsController = require '../controllers/credentials'

Help = require './help'


module.exports = class StackEditor extends kd.View

  EDITORS = ['editor', 'readme', 'variables', 'logs']

  constructor: (options = {}, data = { _initial: yes }) ->

    super options, data

    # In-Memory Snapshot Storage
    @_snapshots = {}
    @_current = null

    # Storage
    @layoutStorage = new FlexSplitStorage
      adapter: AppStorageAdapter

    # Toolbar
    @toolbar = new Toolbar
    @forwardEvent @toolbar, Events.InitializeRequested

    # Status bar
    @statusbar = new Statusbar

    # Editor views
    @editor = new Editor {
      cssClass: 'editor'
      help: Help.stack
      filename: 'template.yaml'
      @statusbar
    }

    @logs = new Editor {
      cssClass: 'logs'
      title: 'Logs'
      filename: 'logs.sh'
      showgutter: no
      readonly: yes
      closable: yes
      @statusbar
    }

    @variables = new Editor {
      cssClass: 'variables'
      title: 'Custom Variables'
      filename: 'variables.yaml'
      help: Help.variables
      @statusbar
    }

    @readme = new Editor {
      cssClass: 'readme'
      title: 'Readme'
      filename: 'readme.md'
      help: Help.readme
      @statusbar
    }

    @controllers = {}

    @controllers.editor = new EditorController
      shared   :
        editor : @editor
        readme : @readme

    @controllers.logs = new LogsController
      shared   :
        editor : @logs

    @controllers.variables = new VariablesController
      shared   :
        editor : @variables
        logs   : @controllers.logs

    # SideView for Search and Credentials
    @controllers.credentials = new CredentialsController
      shared   :
        logs   : @controllers.logs

    @sideView       = new SideView
      title         : yes
      views         :
        credentials :
          title     : 'Credentials'
          cssClass  : 'credentials show-controls has-markdown'
          view      : @controllers.credentials.getView()
          controls  :
            plus    : =>
              { listController } = @controllers.credentials
              listController._createAddCredentialMenuButton
                cssClass : 'plus'
                diff     :
                  x      : -93
                  y      : 12

        docs        :
          title     : 'API Docs'
          cssClass  : 'docs show-controls has-markdown'
          view      : new kd.View { partial: 'WIP' }

    for _, controller of @controllers
      controller.on Events.TemplateDataChanged, @bound 'setData'
      controller.on Events.WarnUser, @toolbar.bound 'setBanner'
      controller.on Events.Action, @bound 'handleActions'

    @toolbar.on Events.Action, @bound 'handleActions'

    @emit 'ready'


  handleActions: (event, rest...) ->

    switch event
      when Events.Menu.Logs
        @logs.resize { percentage: 40, store: yes }
      when Events.Menu.Credentials
        @sideView.show 'credentials'
      when Events.ShowSideView
        @sideView.show rest...
      when Events.ToggleSideView
        @sideView.toggle rest...
      when Events.HideWarning
        @toolbar.banner.emit Events.Banner.Close


  setData: (data, reset = no) ->

    super data

    debug 'setData with args:', data, reset
    return data  if data._initial

    { _id: id, description, template } = data
    unless id or description or template
      throw { message: 'A valid JStackTemplate is required!' }

    @toolbar.setData data

    @controllers.editor.setData data
    @controllers.variables.setData data
    @controllers.credentials.setData data

    @_saveSnapshot @_current  if @_current
    @_deleteSnapshot id  if reset

    unless @_loadSnapshot id

      @editor.setContent Encoder.htmlDecode template.rawContent
      @readme.setContent Encoder.htmlDecode description
      @variables.setContent ''
      @controllers.logs.set 'stack template loaded'

      @_saveSnapshot id
      @_current = id

    kd.utils.defer @editor.bound 'focus'

    return data


  setBusy: (busy = yes) ->

    if busy
      @setClass 'loading'
      @toolbar.actionButton.showLoader()
    else
      @unsetClass 'loading'
      @toolbar.actionButton.hideLoader()


  _loadSnapshot: (id) ->

    return no  unless id
    return no  unless snapshot = @_snapshots[id]

    for view in EDITORS
      @[view]._restore snapshot[view]
    @_current = id

    return yes


  _saveSnapshot: (id) ->

    return  unless id

    @_snapshots[id] ?= {}
    for view in EDITORS
      @_snapshots[id][view] = @[view]._dump()


  _deleteSnapshot: (id) -> delete @_snapshots[id]


  viewAppended: ->

    # Layout
    @addSubView new FlexSplit
      name                : 'stackEditor'
      cssClass            : 'mainview'
      resizable           : no
      views               : [
        @toolbar          # Toolbar on top, fixed height
        new FlexSplit
          resizable       : no
          views           : [
            contentView   = new FlexSplit
              name        : 'contentView'
              cssClass    : 'content'
              views       : [
                new FlexSplit
                  name    : 'leftColumn'
                  views   : [@editor, @logs]
                  sizes   : [90, 10]
                  storage : @layoutStorage
                new FlexSplit
                  name    : 'rightColumn'
                  sizes   : [50, 50]
                  views   : [@variables, @readme]
                  storage : @layoutStorage
              ]
              sizes       : [55, 45]
              type        : FlexSplit.VERTICAL
              storage     : @layoutStorage
            @statusbar    # Statusbar on bottom, fixed height
          ]
      ]

    contentView.setClass 'safari-flex-fix'  if bowser.safari
    contentView.addSubView @sideView
