kd = require 'kd'
module.exports = class PubnubChannel extends kd.Object

  constructor: (options = {}) ->

    super options

    @name      = options.name
    @channelId = options.channelId
