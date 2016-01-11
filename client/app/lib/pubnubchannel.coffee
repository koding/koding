kd = require 'kd'
KDObject = kd.Object
module.exports = class PubnubChannel extends KDObject

  constructor: (options = {}) ->

    super options

    @name      = options.name
    @channelId = options.channelId
