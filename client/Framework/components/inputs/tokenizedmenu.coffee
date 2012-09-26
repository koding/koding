class KDTokenizedMenu extends JContextMenu

  constructor:->

    super
    # log @treeController, ">>>>"
    # @treeController.on 'keyEventPerformedOnTreeView', (event)->
    #   log event.which, "keydown"