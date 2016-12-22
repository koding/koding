kd = require 'kd'
bowser = require 'bowser'
Encoder = require 'htmlencode'

FlexSplit = require './flexsplit'
FlexSplitStorage = require './flexsplit/storage'
AppStorageAdapter = require './adapters/appstorageadapter'

Toolbar = require './toolbar'
Editor = require './editor'
Statusbar = require './statusbar'


module.exports = class StackEditor extends kd.View


  constructor: (options = {}, data = {}) ->

    super options, data

    # In-Memory Snapshot Storage
    @_snapshots = {}
    @_current = null

    # Storage
    @layoutStorage = new FlexSplitStorage
      adapter: AppStorageAdapter

    # Toolbar
    @toolbar = new Toolbar
    @forwardEvent @toolbar, 'InitializeRequested'

    # Status bar
    @statusbar = new Statusbar

    # Editor views
    @editor = new Editor {
      cssClass: 'editor'
      @statusbar
    }

    @logs = new Editor {
      cssClass: 'logs'
      title: 'Logs'
      @statusbar
    }

    @variables = new Editor {
      cssClass: 'variables'
      title: 'Custom Variables'
      @statusbar
    }

    @readme = new Editor {
      cssClass: 'readme'
      title: 'Readme'
      @statusbar
    }

    @emit 'ready'


  setTemplateData: (data) ->

    if data
      @setData data
      @toolbar.setData data

    { _id: id, title, description, template } = @getData()
    unless id or description or template
      throw { message: 'A valid JStackTemplate is required!' }

    @_saveSnapshot @_current  if @_current
    @editor.setOption 'title', title

    unless @_loadSnapshot id

      @editor.setContent Encoder.htmlDecode template.rawContent
      @readme.setContent description
      @logs.setContent 'Stack template loaded'

      @_saveSnapshot id
      @_current = id

    kd.utils.defer @editor.bound 'focus'


  _loadSnapshot: (id) ->

    return no  unless id
    return no  unless snapshot = @_snapshots[id]

    for view in ['editor', 'readme', 'logs']
      @[view]._restore snapshot[view]
    @_current = id

    return yes


  _saveSnapshot: (id) ->

    return  unless id

    @_snapshots[id] ?= {}
    for view in ['editor', 'readme', 'logs']
      @_snapshots[id][view] = @[view]._dump()


  viewAppended: ->

    # Layout
    @addSubView new FlexSplit
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
