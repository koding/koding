debug = (require 'debug') 'nse:toolbar:banner'

kd = require 'kd'


Events = require '../events'


module.exports = class Banner extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'banner', options.cssClass

    data      ?=
      message  : 'Hello world!'
      action   :
        title  : 'Fix'
        event  : Events.Banner.ActionClicked
      _initial : yes

    super options, data

    @_wait = null

    @messageButton = new kd.ButtonView
      cssClass : 'message-button solid blue small'
      title    : @getData 'buttonTitle'

    @closeButton = new kd.ButtonView
      cssClass : 'close-button'
      callback : @bound 'close'


  setData: (data) ->

    closable = data.closable ? yes

    unless data._initial

      if data.sticky is yes
        closable = no
        delete data.sticky
        data.sticky = data

      else if not data.sticky? and sticky = @isSticky()
        data.sticky = sticky

    super data

    { action, autohide, _initial } = @getData()

    unless data._initial

      kd.utils.killWait @_wait

      if action
        @messageButton.setTitle action.title  if action.title
        if typeof action.fn is 'function'
          @messageButton.setCallback action.fn
        else if actionEvent = action.event
          @messageButton.setCallback =>
            @emit Events.Banner.Close
            @emit Events.Action, actionEvent, (action.args ? [])...
        @messageButton.show()
      else
        @messageButton.hide()

      if autohide
        @_wait = kd.utils.wait autohide, @bound 'close'

      if not closable
      then @closeButton.hide()
      else @closeButton.show()

    return data


  close: ->
    @emit Events.Banner.Close


  isSticky: ->
    @getData().sticky


  pistachio: ->
    '''
    {.message{#(message)}}{{> @messageButton}}{{> @closeButton}}
    '''
