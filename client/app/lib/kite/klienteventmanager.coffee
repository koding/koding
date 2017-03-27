kd = require 'kd'

###*
 * The KlientEventManager is a wrapper over Klient events (from
 * `client.Subscribe`) that have repeating callbacks. It serves to
 * provide a cleaner pubsub interface for methods of Klient
 * that make sense using this style.
###
module.exports = class KlientEventManager extends kd.Object

  ###*
   * @param {Object} options - An object where the keys are event names,
   * and the values are callbacks. As an alternative, you can simply
   * use the `@subscribe` method.
  ###
  constructor: (options = {}, machine) ->

    super options, machine

    unless machine
      throw new Error kd.err 'KlientEventManager requires a Machine'

    if @getKite().isDisconnected
      throw new Error 'KlientEventManager requires an active Kite connection'

    @subscribe eventName, callback  for eventName, callback of options


  ###*
   * Subscribe to the given Klient client.Subscribe eventName
   *
   * @param {String} eventName
   * @param {Function()} callback - Called with whatever data the given
   *  eventName responds with.
  ###
  subscribe: (eventName, callback) ->

    return @getKite().clientSubscribe { eventName, onPublish: callback }


  unsubscribe: (eventName, eventId) ->

    return @getKite().clientUnsubscribe { eventName, id: eventId }


  getKite: ->
    @getData().getBaseKite()
