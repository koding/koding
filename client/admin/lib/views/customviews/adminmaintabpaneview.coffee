kd = require 'kd'


module.exports = class AdminMainTabPaneView extends kd.TabView

  constructor: (options = {}, data) ->

    options                =
      cssClass             : 'AppModal--admin-tabs AppModal-content'
      detachPanes          : yes
      maxHandleWidth       : Infinity
      minHandleWidth       : 0
      hideHandleCloseIcons : yes
      tabHandleContainer   : options.tabHandleContainer

    super options, data


  handleClicked: (event, handle) ->

    {pane} = handle.getOptions()

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute "/Admin/#{pane.getOption 'slug'}"
