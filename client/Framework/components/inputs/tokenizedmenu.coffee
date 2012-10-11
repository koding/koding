class KDTokenizedMenu extends JContextMenu

  constructor:(options = {}, data)->

    options.treeItemClass     or= null
    options.listViewClass     or= null
    options.addListsCollapsed or= null
    options.putDepthInfo      or= null

    super options, data
    # log @treeController, ">>>>"
    # @treeController.on 'keyEventPerformedOnTreeView', (event)->
    #   log event.which, "keydown"