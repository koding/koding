debug = (require 'debug') 'nse:toolbar:banner'

kd = require 'kd'
JView = require 'app/jview'

Events = require '../events'


module.exports = class Banner extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'banner', options.cssClass

    data      ?=
      message  : 'Hello world!'
      action   :
        title  : 'Fix'
        event  : Events.Banner.ActionClicked
      _initial : yes

    super options, data

    @messageButton = new kd.ButtonView
      cssClass : 'message-button solid blue small'
      title    : @getData 'buttonTitle'

    @closeButton = new kd.ButtonView
      cssClass : 'close-button'
      callback : @bound 'close'


  setData: (data) ->

    super data

    { action, autohide, _initial } = @getData()

    unless data._initial

      if action
        @messageButton.setTitle action.title  if action.title
        if typeof action is 'function'
          @messageButton.setCallback action
        else if actionEvent = action.event
          @messageButton.setCallback =>
            @emit Events.Banner.Closed
            @emit Events.ToolbarAction, actionEvent, (action.args ? [])...
        @messageButton.show()
      else
        @messageButton.hide()

      if autohide
        kd.utils.wait autohide, @bound 'close'

    return data


  close: ->
    @emit Events.Banner.Closed


  pistachio: ->
    '''
    {.message{#(message)}}{{> @messageButton}}{{> @closeButton}}
    '''
