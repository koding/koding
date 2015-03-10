kd                  = require 'kd'
Encoder             = require 'htmlencode'
KDHitEnterInputView = kd.HitEnterInputView
whoami              = require 'app/util/whoami'


module.exports = class ActivityInputView extends KDHitEnterInputView

  ENTER = 13
  TAB   = 9

  constructor: (options = {}, data) ->

    options.cssClass              = kd.utils.curry "input-view", options.cssClass
    options.autogrow             ?= yes
    options.minHeight            ?= 54
    options.showButton           ?= yes
    options.placeholder          ?= "Hey #{Encoder.htmlDecode whoami().profile.firstName}, share something interesting or ask a question."
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


  keyDown: (event) ->

    if event.which is TAB
      kd.utils.stopDOMEvent event
      @emit 'tab'
      return no

    super event

    @emit 'EnterPerformed'  if event.which is ENTER and event.metaKey



