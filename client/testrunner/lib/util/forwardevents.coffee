###*
 * if reducer returns an array it will be passed as arguments to emit call. If
 * you want to really emit an event that returns an array, return an object that
 * wraps that array.
 *
 * @param {EventEmitter} from
 * @param {EventEmitter} to
 * @param {string|Array.<string>} events
 * @param {function=} reducer
###
module.exports = forwardEvents = (from, to, events, reducer) ->

  events = [events]  unless Array.isArray events

  # default it to id function.
  reducer ?= (event) -> [event]

  events.map (event) ->
    from.on event, (args...) ->
      # pass handler args to reducer and get a new payload to be passed to emit
      # call.
      payload = reducer args...

      # allow arbitrary results to be passed, cast them to array so that those
      # can be expanded, this also gives a handy way to pass multiple
      # parameters to emit call.
      payload = [payload]  unless Array.isArray payload

      to.emit event, payload...
