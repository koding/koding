kd = require 'kd'

module.exports = class ShowcaseAppView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'ShowcaseApp'

    super options, data
