class ActivityInputView extends KDHitEnterInputView

  constructor: (options = {}, data) ->

    options.cssClass              = KD.utils.curry "input-view", options.cssClass
    options.autogrow             ?= yes
    options.minHeight            ?= 54
    options.showButton           ?= yes
    options.placeholder          ?= "Hey #{Encoder.htmlDecode KD.whoami().profile.firstName}, share something interesting or ask a question."
    options.attributes          or= {}
    options.attributes.testpath or= "ActivityInputView"
    options.attributes.rows     or= 1
    validate                      =
      required                    : yes

    super options, data

    @on 'EnterPerformed', @bound 'handleEnter'


  handleEnter: ->

    return  unless value = @getValue().trim()

    @emit 'Enter', value

    if value.match '/pmtest'

      [_, milliseconds, totalCount] = value.split ' '

      count = 0
      interval = KD.utils.repeat milliseconds, =>

        return window.clearInterval interval  if count > totalCount

        @emit 'Enter', "#{count}-#{KD.nick()}"
        count++


  empty: ->
    @setValue ''
    @resize()

  keyDown: (event) ->
    super event

    if event.which is 13 and event.metaKey
      @emit 'EnterPerformed'
