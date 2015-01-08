class WebTermMessagePane extends KDCustomScrollView


  constructor: (options = {}, data)->

    options.cssClass = KD.utils.curry \
      'message-pane console ubuntu-mono green-on-black', options.cssClass

    super options, data

  busy: ->

    @loader.updatePartial 'Connecting'

    @message.hide()
    @loader.show()

    @show()

    @loader.repeater = KD.utils.repeat 200, @loader.lazyBound 'setPartial', '.'

  hide: ->

    super

    KD.utils.killRepeat @loader.repeater


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

    KD.utils.killRepeat @loader.repeater
    @loader.hide()

    if err.message is "ErrNoSession"

      @setMessage \
        "This session is not valid anymore,
        click here to create a new one.", 'RequestNewSession'

      return yes

    else if err.name is "TimeoutError"

      @setMessage \
        "Failed to connect your terminal,
        click here to try again.", 'RequestReconnect'

      return yes

    return no
