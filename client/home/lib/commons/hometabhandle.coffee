kd = require 'kd'

module.exports = class HomeTabHandle extends kd.TabHandleView

  constructor: (options = {}, data) ->

    options.tagName    = 'a'
    options.attributes =
      href             : "/Home/#{kd.utils.slugify options.pane.getOption 'title'}"

    super options, data
