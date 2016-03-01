_                         = require 'lodash'
kd                        = require 'kd'
KDContextMenu             = kd.ContextMenu
IDEStatusBarMenuItem      = require './idestatusbarmenuitem'
IDESyntaxSelectorMenuItem = require './idesyntaxselectormenuitem'
{ presentBinding }        = require 'app/shortcutscontroller'


module.exports = class IDEStatusBarMenu extends KDContextMenu

  constructor: (options = {}) ->

    { delegate, paneType } = options

    options.x              ?= delegate.getX() - 5
    options.y              ?= delegate.getY() + 20
    options.cssClass      or= "IDE-StatusBarMenu #{paneType}-context-menu"
    options.treeItemClass or= IDEStatusBarMenuItem

    super options, @getItems paneType

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      @destroy()  unless event.target.parentNode.classList.contains 'kdselectbox'


  getItems: (paneType) ->

    { shortcuts, appManager } = kd.singletons

    collection = shortcuts.toCollection()

    subcollections =
      editor: collection.find _key: 'editor'
      workspace: collection.find _key: 'workspace'

    itemsData = @getItemsData paneType
    _
      .chain itemsData
      .chunk 2
      .reduce (acc, pair) ->
        [ key, value ] = pair

        if _.isString value
          obj = { callback: appManager.tell.bind appManager, 'IDE', value }
          if key.indexOf('.') is -1 #regular menu items
            obj.title = key
          else #shortcut menu items
            [ collectionName, modelName ] = key.split '.'
            { description, binding } = subcollections[collectionName].find name: modelName
            obj.shortcut = presentBinding _.first binding
        else
          obj =
            type: 'customView'
            view: value

        acc[description or key] = obj

        acc
      , {}
      .value()


  getItemsData: (paneType) ->

    if paneType is 'terminal'
      return [
        'Rename'  , 'showRenameTerminalView'
        'Suspend' , 'suspendTerminal'
      ]

    @syntaxSelector = new IDESyntaxSelectorMenuItem
    return [
      # Shortcut                 # IDE method
      'editor.save'              , 'saveFile'
      'editor.saveas'            , 'saveAs'
      'workspace.saveallfiles'   , 'saveAllFiles'
      'Syntax'                   , @syntaxSelector # Title/Instance
      'workspace.previewfile'    , 'previewFile'
      'editor.find'              , 'showFindView'
      'editor.replace'           , 'showFindAndReplaceView'
      'workspace.searchallfiles' , 'showContentSearch'
      'workspace.findfilebyname' , 'showFileFinder'
      'editor.gotoline'          , 'goToLine'
      'Rename'                   , 'showRenameTerminalView'
    ]
