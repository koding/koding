class ActivityInputView extends KDHitEnterInputView

  constructor: (options = {}, data) ->

    options.cssClass              = KD.utils.curry "input-view", options.cssClass
    options.autogrow             ?= yes
    options.minHeight            ?= 54
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


  empty: ->
    @setValue ''
    @resize()