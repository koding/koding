kd = require 'kd'
FSHelper = require 'app/util/fs/fshelper'
NFinderTreeController = require 'finder/filetree/controllers/nfindertreecontroller'
IDEHelpers = require '../idehelpers'


module.exports = class IDEFinderTreeController extends NFinderTreeController



  cmCreateTerminal:  (node) -> @createTerminal  node


  createTerminal: (node) ->

    { path, machine } = node.getData()
    appManager        = kd.getSingleton 'appManager'
    path              = FSHelper.plainPath path

    appManager.tell 'IDE', 'createNewTerminal', { machine, path }


  collapseFolder: (nodeView, callback, silence) ->

    kallback = (nodeView) =>
      callback?.call this, nodeView

      return  if @dontEmitChangeEvent

      @emit 'FolderCollapsed', nodeView.getData().path


    super nodeView, kallback, silence


  expandFolder: (nodeView, callback, silence) ->

    kallback = (err, nodeView) =>
      callback?.call this, err, nodeView

      return  if @dontEmitChangeEvent

      @emit 'FolderExpanded', nodeView.getData().path  if nodeView

    super nodeView, kallback, silence
