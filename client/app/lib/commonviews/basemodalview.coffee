kd = require 'kd'

module.exports = class BaseModalView extends kd.BlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'BaseModalView', options.cssClass

    super options, data
