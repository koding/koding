sendDataDogEvent = require '../util/sendDataDogEvent'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDCustomScrollView = kd.CustomScrollView
module.exports = class WebTermMessagePane extends KDCustomScrollView


  constructor: (options = {}, data)->

    options.cssClass = kd.utils.curry \
      'message-pane console ubuntu-mono green-on-black', options.cssClass

    super options, data

  busy: ->

    @off 'click'

    @loader.updatePartial 'Connecting'

    @message.hide()
    @loader.show()

    @show()

    @loader.repeater = kd.utils.repeat 200, @loader.lazyBound 'setPartial', '.'

  hide: ->

    super

    kd.utils.killRepeat @loader.repeater


  viewAppended: ->

    super

    @wrapper.addSubView @message = new KDCustomHTMLView
    @wrapper.addSubView @loader  = new KDCustomHTMLView
      partial: 'Connecting'


  setMessage: (message, signal)->

    @message.updatePartial message

    @off 'click'
    @on  'click', @lazyBound 'emit', signal

    @message.show()

    @show()


  handleError: (err)->

    kd.utils.killRepeat @loader.repeater
    @loader.hide()

    if err.message is "ErrNoSession"

      @setMessage \
        "This session is not valid anymore,
        click here to create a new one.", 'RequestNewSession'

    else if err.name is "TimeoutError"

      @setMessage \
        "Failed to connect your terminal,
        click here to try again.", 'RequestReconnect'

      sendDataDogEvent "TerminalConnectionFailed"

    else if err.message is "session limit has reached"

      @setMessage \
        "You have too many sessions opened,
        click here to dismiss.", "DiscardSession"

    else

      @setMessage \
        "An unknown error occured, please open a new tab.
        Click here to dismiss this one.", "DiscardSession"

      warn "[Webterm]", err
