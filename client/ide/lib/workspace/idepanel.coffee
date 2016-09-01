kd                        = require 'kd'
KDView                    = kd.View
IDEDrawingPane            = require './panes/idedrawingpane'
IDEEditorPane             = require './panes/ideeditorpane'
IDETailerPane             = require './panes/idetailerpane'
IDEFinderPane             = require './panes/idefinderpane'
IDETerminalPane           = require './panes/ideterminalpane'
IDEWorkspaceLayoutBuilder = require './ideworkspacelayoutbuilder'


module.exports = class IDEPanel extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'panel', options.cssClass

    super options, data

    @panesContainer = []
    @panes          = []
    @panesByName    = {}

    @createLayout()

  createLayout: ->
    { layoutOptions }  = @getOptions()

    unless layoutOptions
      throw new Error 'You should pass layoutOptions to create a panel'

    layoutOptions.delegate = this

    @layout = new IDEWorkspaceLayoutBuilder layoutOptions
    @addSubView @layout

  createPane: (paneOptions) ->
    PaneClass = @getPaneClass paneOptions
    pane      = new PaneClass paneOptions

    @panesByName[paneOptions.name] = pane  if paneOptions.name

    @panes.push pane
    @emit 'NewPaneCreated', pane
    return pane

  getPaneClass: (paneOptions) ->
    paneType  = paneOptions.type
    PaneClass = if paneType is 'custom' then paneOptions.paneClass else @findPaneClass paneType

    unless PaneClass
      throw new Error "PaneClass is not defined for \"#{paneOptions.type}\" pane type"

    return PaneClass

  findPaneClass: (paneType) ->
    paneClasses =
      terminal  : IDETerminalPane
      editor    : IDEEditorPane
      finder    : IDEFinderPane
      drawing   : IDEDrawingPane
      tailer    : IDETailerPane

    return paneClasses[paneType]

  getPaneByName: (name) ->
    return @panesByName[name] or null
