kd                  = require 'kd'
Encoder             = require 'htmlencode'
KDHitEnterInputView = kd.HitEnterInputView
whoami              = require 'app/util/whoami'


module.exports = class ActivityInputView extends KDHitEnterInputView

  ENTER      = 13
  TAB        = 9
  UP_ARROW   = 38
  DOWN_ARROW = 40
  ESC        = 27

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

    switch event.which
      when TAB
        kd.utils.stopDOMEvent event
        @emit 'Tab'
        return no
      when ESC
        @emit 'Esc', event
      when UP_ARROW
        @emit 'UpArrow', event
      when DOWN_ARROW
        @emit 'DownArrow', event
      when ENTER
        @emit 'RawEnter', event

    super event

    @emit 'EnterPerformed'  if event.which is ENTER and event.metaKey
