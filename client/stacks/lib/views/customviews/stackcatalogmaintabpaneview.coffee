kd = require 'kd'


module.exports = class StackCatalogMainTabPaneView extends kd.TabView

  constructor: (options = {}, data) ->

    options                =
      cssClass             : 'AppModal--admin-tabs AppModal-content'
      detachPanes          : yes
      maxHandleWidth       : Infinity
      minHandleWidth       : 0
      hideHandleCloseIcons : yes
      tabHandleContainer   : options.tabHandleContainer
      useRouter            : options.useRouter ? yes

    super options, data


  handleClicked: (event, handle) ->

    if @getOption 'useRouter'

      {pane} = handle.getOptions()

      kd.utils.stopDOMEvent event
      kd.singletons.router.handleRoute "/Stacks/#{pane.getOption 'slug'}"

    else
      super event, handle
