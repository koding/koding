kd = require 'kd'
KDContextMenu = kd.ContextMenu
IDEStatusBarMenuItem = require './idestatusbarmenuitem'
IDESyntaxSelectorMenuItem = require './idesyntaxselectormenuitem'
{ presentBinding } = require 'app/shortcutscontroller'
_ = require 'lodash'

module.exports =

class IDEStatusBarMenu extends KDContextMenu

  constructor: (options) ->

    { delegate } = options

    defaults =
      menuWidth     : 220
      x             : delegate.getX() - 5
      y             : delegate.getY() + 20
      cssClass      : 'status-bar-menu'
      treeItemClass : IDEStatusBarMenuItem

    super _.extend(defaults, options), @getItems()

    @on 'ContextMenuItemReceivedClick', (view, event) =>
      unless event.target.parentNode.classList.contains 'kdselectbox'
        @destroy()


  getItems: ->

    { shortcuts, appManager } = kd.singletons

    collection = shortcuts.toCollection()

    subcollections =
      editor: collection.find _key: 'editor'
      workspace: collection.find _key: 'workspace'

    @syntaxSelector = new IDESyntaxSelectorMenuItem

    _
      .chain [
        # Shortcut                 # IDE method
        'editor.save'              , 'saveFile'
        'editor.saveas'            , 'saveAs'
        'workspace.saveallfiles'   , 'saveAllFiles'
        'Syntax'                   , @syntaxSelector # Title/Instance
        'workspace.previewfile'    , 'previewFile'
        'editor.find'              , 'showFindReplaceView'
        'editor.replace'           , 'showFindReplaceViewWithReplaceMode'
        'workspace.searchallfiles' , 'showContentSearch'
        'workspace.findfilebyname' , 'showFileFinder'
        'editor.gotoline'          , 'goToLine'
      ]
      .chunk 2
      .reduce (acc, pair) ->
        [ key, value ] = pair

        if _.isString value
          [ collectionName, modelName ] = key.split '.'
          { description, binding } = subcollections[collectionName].find name: modelName
          obj =
            shortcut: presentBinding _.first binding
            callback: appManager.tell.bind appManager, 'IDE', value
        else
          obj =
            type: 'customView'
            view: value

        acc[description or key] = obj

        acc
      , {}
      .value()
