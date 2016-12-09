kd = require 'kd'

module.exports = class AddonsTabHandle extends kd.TabHandleView

  constructor: (options = {}, data) ->

    options.tagName         = 'a'
    options.attributes    or= {}
    options.attributes.href = "/Home/add-ons/#{kd.utils.slugify options.pane.name}"

    super options, data
