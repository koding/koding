
class Timer


  constructor: (callback, delay = 0) ->

    @callback = callback
    @delay = delay
    @timerId = null
    @start = null
    @remaining = delay
    @resume()

  pause: ->

    clearTimeout @timerId
    @remaining -= new Date - @start


  resume: ->

    @start = new Date
    clearTimeout @timerId
    @timerId = setTimeout @callback, @remaining


  clear: ->
    clearTimeout @timerId


validateProps = (notification, types) ->

  if not notification.type
    throw new Error('Notification type is required.')
  if Object.keys(types).indexOf(notification.type) is -1
    throw new Error("\"#{notification.type} \" is not a valid type.")
  if isNaN(notification.duration)
    throw new Error('\"duration\" must be a number.')

module.exports = { Timer, validateProps }
