kd          = require 'kd'
WebTermView = require 'app/terminal/webtermview'


module.exports = class IDEWebTermView extends WebTermView


  viewAppended: ->

    super

    # Call the "triggerFitToWindow" when terminal is connected.
    if @getOption('mode') is 'shared'
      @on 'WebTermConnected', @bound 'triggerFitToWindow'
