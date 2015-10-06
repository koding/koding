kd            = require 'kd'
React         = require 'kd-react'
keyboardKeys  = require 'app/util/keyboardKeys'
showError     = require 'app/util/showError'
validator     = require 'validator'
ActivityFlux  = require 'activity/flux'


module.exports = DropboxInputMixin =

  getDropdown: -> @refs.dropdown


  onKeyDown: (event) ->

    { TAB, ESC, ENTER, UP_ARROW, DOWN_ARROW, BACKSPACE } = keyboardKeys

    switch event.which
      when BACKSPACE   then @onBackspace? event
      when ENTER       then @onEnter event
      when ESC         then @onEsc event
      when TAB         then @onNextPosition event, { isTab : yes }
      when DOWN_ARROW  then @onNextPosition event, { isDownArrow : yes }
      when UP_ARROW    then @onPrevPosition event, { isUpArrow : yes }


  onEnter: (event) ->

    return  if event.shiftKey

    kd.utils.stopDOMEvent event

    dropdown = @getDropdown()

    if dropdown.isActive()

      dropdown.confirmSelectedItem()

    else if @isGroupAdmin and @isGroupAdmin()

      value        = event.target.value.trim()
      isValidEmail = validator.isEmail value

      return showError 'That doesn\'t seem like a valid email address.'  unless isValidEmail

      ActivityFlux.actions.channel.inviteMember [{email: value}], =>
        @setState value: ''


  onEsc: (event) -> @getDropdown().close()


  onNextPosition: (event, keyInfo) ->

    dropdown = @getDropdown()

    if dropdown.isActive()

      stopEvent = dropdown.moveToNextPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent


  onPrevPosition: (event, keyInfo) ->

    dropdown = @getDropdown()

    if dropdown.isActive()

      stopEvent = dropdown.moveToPrevPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent

