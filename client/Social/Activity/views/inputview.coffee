class ActivityInputView extends KDHitEnterInputView

  constructor: (options = {}, data) ->

    options.cssClass              = KD.utils.curry "input-view", options.cssClass
    options.autogrow             ?= yes
    options.minHeight            ?= 54
    options.placeholder          ?= "What's new #{KD.whoami().profile.firstName}?"
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