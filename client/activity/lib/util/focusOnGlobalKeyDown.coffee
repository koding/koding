kd   = require 'kd'
KEYS = require 'app/util/keyboardKeys'
$    = require 'jquery'

module.exports = focusOnGlobalKeyDown = (input) ->

  { windowController } = kd.singletons

  windowController.on 'keydown', (event) =>

    { TAB, ESC, ENTER, SPACE, CTRL, CMD } = KEYS

    key       = event.which
    # to be able to copy to clipboard anywhere on the page
    C_KEY     = 67
    isCopying = key is C_KEY and (event.metaKey or event.ctrlKey)

    keyboardElements  = "input,textarea,select,datalist,keygen,[contenteditable='true'],button"
    { activeElement } = document

    return  if input is activeElement
    # do not break accessibility
    return  if key in [ ENTER, TAB, SPACE, ESC, CTRL, CMD ] or isCopying

    nothingFocused  = not $(activeElement).is keyboardElements
    inputInViewport = input.offsetParent
    # temp: until modals are made stateful
    noActiveModals  = !($('body > .kdmodal').length + $('body > div > .Modal').length)

    input.focus()  if nothingFocused and inputInViewport and noActiveModals
