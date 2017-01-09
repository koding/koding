kd = require 'kd'
LinkView = require './linkview'


module.exports = class AppLinkView extends LinkView

  constructor: (options = {}, data) ->

    options.cssClass = 'app'

    super options, data

    # FIXME something wrong with setTooltip
    @on 'OriginLoadComplete', (data) =>
      kd.log data
      @setTooltip
        title     : data.body
        placement : 'above'
        delayIn   : 120
        offset    : 1

      # FIXME GG, Need to implement AppIsDeleted
      data.on? 'AppIsDeleted', =>
        @destroy()

  pistachio: ->

    super '{{#(title)}}'
