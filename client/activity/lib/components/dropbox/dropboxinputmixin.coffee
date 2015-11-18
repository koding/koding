kd            = require 'kd'
$             = require 'jquery'
React         = require 'kd-react'
keyboardKeys  = require 'app/util/keyboardKeys'


module.exports = DropboxInputMixin =

  getDropdown: -> @refs.dropdown


  onKeyDown: (event) ->

    { TAB, ESC, ENTER, UP_ARROW, DOWN_ARROW, BACKSPACE } = keyboardKeys

    switch event.which
      when BACKSPACE   then @onBackspace? event
      when ENTER       then @onEnter event
      when TAB         then @onNextPosition event, { isTab : yes }
      when DOWN_ARROW  then @onNextPosition event, { isDownArrow : yes }
      when UP_ARROW    then @onPrevPosition event, { isUpArrow : yes }


  onEnter: (event) ->

    return  if event.shiftKey

    kd.utils.stopDOMEvent event

    dropdown = @getDropdown()

    if dropdown.isActive()

      return dropdown.confirmSelectedItem()

    @onAfterEnter?()


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

