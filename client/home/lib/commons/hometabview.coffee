kd = require 'kd'

module.exports = class HomeTabView extends kd.TabView

  constructor: (options = {}, data) ->

    super options, data


  handleClicked: (event, handle) ->

    { pane } = handle.getOptions()

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute "/Home/#{kd.utils.slugify pane.getOption 'title'}"
