'use strict'

module.exports = class Channel
  constructor:(@channel)->
    for method, fn of channel when 'function' is typeof fn
      @[method] = fn.bind(channel)
    @on   = @bind
    @emit = @trigger
