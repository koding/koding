kd                         = require 'kd'
{ TAB, ESC, ENTER, SPACE } = require 'app/util/keyboardKeys'

module.exports = focusOnGlobalKeyDown = (input) ->

  { windowController } = kd.singletons

  windowController.on 'keydown', (event) =>

    keyboardElements  = "input,textarea,select,datalist,keygen,[contenteditable='true'],button"
    { activeElement } = document

    return  if input is activeElement
    # do not break accessibility
    return  if event.which in [ ENTER, TAB, SPACE, ESC ]

    nothingFocused  = not $(activeElement).is keyboardElements
    inputInViewport = input.offsetParent
    # temp: until modals are made stateful
    noActiveModals  = !($('body > .kdmodal').length + $('body > div > .Modal').length)

    input.focus()  if nothingFocused and inputInViewport and noActiveModals
