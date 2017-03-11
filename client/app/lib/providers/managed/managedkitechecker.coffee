kd      = require 'kd'
helpers = require './helpers'


# The default delay (in seconds) that ManagedKiteChecker will wait on
# new listenrs.
DEFAULT_DELAY = 30

# The default interval (in seconds) between ticks.
DEFAULT_INTERVAL = 10

# The default maximum number of ticks that a single listener will
# trigger via the interval.
DEFAULT_MAX_TICKS = 60


# ManagedKiteChecker is a singleton in ComputeController for listening for
# new managed kites from Kontrol.
#
# ManagedKiteChecker will inform a *single* listener of a new kite at a
# time. New kites are not broadcasted to listeners. The logic behind
# this is that a ManagedKiteChecker listener has ownership of the new
# kite.
#
# If (for some reason) you need to listen for all new kites, kites
# are also emitted via an @emit on 'NewKite', and can be subscribed to
# with @on and @off, as expected. It's worth noting that a listener is
# required for the NewKite event to be emitted, currently.
#
module.exports = class ManagedKiteChecker extends kd.Object

  ###*
   * @param {Number} options.delay - The delay (in seconds) that the
   *  first tick will be called after. This applies to each listener
   *  currently, and is not offset from actual total waited time. Eg,
   *  if the 5th listener has been waiting for 4 other listeners, it
   *  will wait (at minimum) `options.delay * 5`.
   *
   * @param {Number} options.interval - The interval rate (in seconds)
   *  at which @tick is called.
   *
   * @param {Number} options.maxTicks - The maximum number of ticks
   *  that ManagedKiteChecker will poll Kontrol for a single
   *  listener. The Tick Count is reset for each new current listener.
  ###
  constructor: (options = {}) ->

    super
      delay    : (options.delay ? DEFAULT_DELAY) * 1000
      interval : (options.interval ? DEFAULT_INTERVAL) * 1000
      maxTicks : options.maxTicks ? DEFAULT_MAX_TICKS

    @_listeners = []
    @_delaying  = no
    @_ticking   = no
    @_tickCount = 0
    @_timerId   = null


  ###*
   * _callListener is a conenience func for calling the zero index
   * listener, removing it from the listeners list, and stopping
   * listening if there are no other listeners.
   *
   * This is useful to call it a listener with an error, without having
   * to muck about with anything else.
   *
   * @param {...} args - The arguments to pass to the listener.
  ###
  _callListener: (args...) ->
    unless @_listeners.length
      kd.warn 'ManagedKiteChecker: _callListener called without
        and listeners'
      return

    @_getListener() args...


  ###*
   * _getListener is a conenience func for getting the zero index
   * listener, removing it from the listeners list, and stopping
   * listening if there are no other listeners.
   *
   * @returns {Function()} listener
  ###
  _getListener: ->

    listener = @_listeners[0]
    @removeListener listener
    return listener


  ###*
   * Handle a new kite if there are any listeners for it. If there are not,
   * it is ignored.
   *
   * Note that a single @tick may return multiple new Kites, which will
   * then trigger this func multiple times. This is why we aggressively
   * shift a listener off of the listener list on each call to this func.
   *
   * @emits NewKite~Kite,info,machine - The NewKite event is emitted
   *  for all new kites. The kite is the kite itself, info is the
   *  response from `klient.info` (containing information about the VM),
   *  and machine is the Machine created for the given kite.
  ###
  _handleNewKiteIfListener: (kite) ->

    # If there are no listeners to handle this kite, do nothing. Future
    # queries will still return the no-machine kite, so they handle it.
    unless @_listeners.length
      return

    { computeController } = kd.singletons
    { createMachine }     = helpers

    listener = @_getListener()

    # Create a machine for this kite.
    createMachine kite, (err, machine) =>
      return kd.error err  if err

      # Get the klient kite, and the info from that klient so we
      # can popup a Provider specific modal
      klient = machine.getBaseKite()
      klient.klientInfo().nodeify (err, payload) =>
        return kd.error err  if err

        # Record the managedProvider in the machine. We don't need to
        # wait for the callback though.
        managedProvider = payload.providerName
        computeController.update machine, { managedProvider }

        # Notify the lisetener, and emit the event.
        listener payload, machine
        @emit 'NewKite', kite, payload, machine


  ###*
   * _stop will stop any currently running ticker or delay (if any), as
   * well as healing any inconsistencies in the delaying/ticking state
   * tracking _(not that there should be any)_.
   *
   * @returns {Boolean} stopped - If true, a ticker or delay was stopped.
   *  If false, nothing was stopped.
  ###
  _stop: ->

    stopped = no

    if @_delaying
      @_delaying = no
      if @_timerId
        kd.utils.killWait @_timerId
        stopped = yes

    if @_ticking
      @_ticking = no
      if @_timerId
        kd.utils.killRepeat @_timerId
        stopped = yes

    return stopped


  ###*
   * _startDelay sets a single timeout, and starting the ticker at the
   * end.
  ###
  _startDelay: ->

    # Be paranoid about duplicating timers.
    if @_delaying or @_ticking
      return kd.error 'ManagedKiteChecker:
        _startDelay called with pre-existing timer or interval'

    @_delaying = yes
    @_timerId  = kd.utils.wait @getOption('delay'), =>
      @_delaying = no
      @_startTicking yes


  ###*
   * _startTicking starts an interval timer to @tick at the rate of
   * @options.interval.
   *
   * @param {Boolean} immediate - If true, a @tick will be called without
   * any interval delay. Subsequent ticks will be called at interval rate
   * as expected.
  ###
  _startTicking: (immediate = no) ->

    # Be paranoid about duplicating timers.
    if @_delaying or @_ticking
      return kd.error 'ManagedKiteChecker:
        _startTicking called with pre-existing timer or interval'

    @_ticking = yes
    @_timerId = kd.utils.repeat @getOption('interval'), @bound 'tick'

    # Call @tick *after* setting the interval, so that @tick can
    # stop it immediately, if wanted.
    @tick()  if immediate


  ###*
   * Add a listener to be notified of a new kite. This listener will
   * only be notified of the Nth new kite, where N is the total number
   * of listeners.
   *
   * For example, if this listener is the first listener, it will be
   * notified of the first new kite. The second, third, and etc listeners
   * will not be notified of that kite. See ManagedKiteChecker for a
   * high level understanding of why this is.
   *
   * @param {Function(info:Object, machine:Machine)} listener -
   *  A callback for when the new kite is connected. Info is the
   *  returned object from the klient kite's `klient.info` method.
   *  This contains the `providerName` key, among other things.
  ###
  addListener: (listener) ->

    # Rather than defaulting listener and start ticking, if callback
    # is null, don't do anything.
    unless listener
      return

    @_listeners.push listener

    # If we're already running, nothing needs to be done.
    return  if @running()

    # Now simply start the delay. Which will then call the ticker, and
    # start ticking - eventually calling the listener.
    @_startDelay()

    # Don't return the delay id
    return


  ###*
   * Remove a listener from ManagedKiteChecker. If no other listeners
   * are currently listening, any Polling (ticking) that may be occuring
   * is halted.
   *
   * @param {Function(info:Object, machine:Machine)} listener -
   *  A callback for when the new kite is connected. Info is the
   *  returned object from the klient kite's `klient.info` method.
   *  This contains the `providerName` key, among other things.
  ###
  removeListener: (listener = kd.noop) ->

    # If there are no listeners, we have nothing to do.
    unless @_listeners.length
      return

    indexOf = @_listeners.indexOf listener

    return  if indexOf < 0

    @_listeners.splice indexOf, 1

    # If there are no more listeners, stop our timeout/interval.
    @_stop()  if @_listeners.length is 0


  ###*
   * Returns whether or not the ManagedKiteChecker is currently running.
   * Ie, has listeners and is actively listening.
   *
   * @returns {Boolean}
  ###
  running: -> @_delaying or @_ticking


  ###*
   * Tick is a heartbeat of the ManagedKiteChecker, called on each
   * interval.
  ###
  tick: ->

    { queryKites } = helpers

    # Increase the tickCount above all else - something called this,
    # so this position makes sure we have a record of the attempt..
    # if it's ever needed.
    @_tickCount++

    # If there are no listeners, there's not much we can tick.
    unless @_listeners.length
      return

    if @_tickCount > @getOption 'maxTicks'
      @_stop()
      return kd.error "ManagedKiteChecker: Maximum tick limit of
        #{@getOption 'maxTicks'} reached."

    queryPromise = queryKites()
    queryPromise.then (kites) =>
      # No kites ready, wait for another tick
      unless kites?.length
        return

      foundNewKite = no
      # Find a new kite, from the kite list.
      # We are judging a "new" kite, as one that doesn't have a machine.
      for kite in kites
        continue  if kite?.machine
        foundNewKite = yes
        @_handleNewKiteIfListener kite

      # If we found new kites, stop the current interval and then
      # start the delay. This ensures that a listener never queries from
      # Kontrol in less time than the delay.
      if foundNewKite and @_listeners.length
        @_stop()
        @_startDelay()

    queryPromise.catch (err) ->
      kd.error err  if err
