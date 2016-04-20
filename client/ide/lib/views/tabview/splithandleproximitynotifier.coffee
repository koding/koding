kd = require 'kd'

# to use only one single event handler for mouse move
# we are tracking listeners ourselves.
_listeners = []

window.addEventListener 'mousemove', (event) ->
  # call every listener on listeners registry.
  listener event  for listener in _listeners

addMouseMoveListener = (listener) ->
  _listeners.push listener
  return listener

removeMouseMoveListener = (listener) ->
  index = _listeners.indexOf listener
  _listener.splice index, 1
  return listener

module.exports = class ProximityNotifier extends kd.Object

  constructor: (options) ->

    super options

    @_visible = no

    @_handler = (event) =>
      isInside = options.handler event
      if @_visible and not isInside
        @emit 'MouseOutside'
        @_visible = no
      else if not @_visible and isInside
        @emit 'MouseInside'
        @_visible = yes

    addMouseMoveListener @_handler

  removeHandler: -> removeMouseMoveListener @_handler
