kd = require 'kd'

module.exports = class HomeStacksTabHandle extends kd.TabHandleView

  constructor: (options = {}, data) ->

    options.tagName         = 'a'
    options.attributes    or= {}
    options.attributes.href = "/Home/stacks/#{kd.utils.slugify options.pane.name}"

    super options, data


  # click: (event) ->

  #   kd.utils.stopDOMEvent event

  #   return no
