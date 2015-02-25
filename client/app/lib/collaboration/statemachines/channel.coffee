machina = require 'machina'
kd      = require 'kd'
getNick = require 'app/util/nick'

remote = require('app/remote').getInstance()

create = (channelId) ->

  channelMachine = new machina.Fsm
    initialState: 'loading'
    states:
      ###*
       * Initial decision state.
       *
       * It will:
       * - fetch the channel with given id if `channelId` is present.
       * or
       * - switch state to 'uninitialized' if no `channelId` is present.
      ###
      loading:
        _onEnter: ->
          return @transition 'uninitialized'  unless channelId
          @transition 'busy'
          @_fetchChannel channelId,
            success : => @handle 'channelReady'
            error   : (error) => handleError error

      ###*
       * State to indicate that there is some operation happening.
      ###
      busy:
        channelReady: (channel) ->
          @emit 'ChannelReady', { channel }
          @transition 'ready'

        participantAdded: (userId) ->
          @emit 'ParticipantAdded', { id: userId }
          @transition 'ready'

        participantRemoved: (userId) ->
          @emit 'ParticipantRemoved', { id: userId }
          @transition 'ready'

        channelDestroyed: ->
          @emit 'ChannelDestroyed'
          @transition 'loading'


      ###*
       * This state means basically it is ready but still doesn't
       * have any `SocialChannel` instance. But it means that, it is ready to
       * be initialized.
       *
       * Only `init` action can happen here.
      ###
      uninitialized:
        _onEnter: ->
          @channel = null

        init: ->
          @transition 'busy'
          @_initChannel
            success : => @handle 'channelReady'
            error   : (error) => handleError error

        '*': -> @deferUntilTransition()

      ###*
       * State to indicate that collaboration channel
       * instance is ready for action.
      ####
      ready:
        terminate: ->
          @transition 'busy'
          @_destroyChannel
            success : => @handle 'channelDestroyed'
            error   : (error) -> handleError error

        addParticipant: (userId) ->
          @transition 'busy'
          @_addParticipant userId,
            success : => @handle 'participantAdded'; console.log 'hello'
            error   : (error) -> handleError error

        removeParticipant: (userId) ->
          @transition 'busy'
          @_removeParticipant userId,
            success : => @handle 'participantRemoved'
            error   : (error) -> handleError error

        '*': ->
          @deferUntilTransition()
          @transition 'busy'


    ###*
     * Action to get healthcheck from outside.
     * It's an asyncronous action. Result is dispatched with
     * an event.
     *
     * @event ChannelStateMachine#HealthCheckDone
     * @type {boolean} success - indicates if result is successful.
     *
     * @emits 'HealthCheckDone'
    ####
    healthcheck: ->
      goodStates = ['ready']
      @emit 'HealthCheckDone', @state in goodStates

    ###*
     * Action to initiate a collaboration channel.
     *
     * @state 'uninitialized'
     * @nextState 'ready'
     * @via 'busy'
    ###
    init: -> @handle 'init'

    ###*
     * Action to terminate a collaboration channel.
     *
     * @state 'ready'
     * @nextState 'uninitialized'
     * @via 'busy'
    ###
    terminate: -> @handle 'terminate'

    ###*
     * Action to add a participant to collaboration channel.
     *
     * @state 'ready'
     * @nextState 'uninitialized'
     * @via 'busy'
    ###
    addParticipant: (userId) -> @handle 'addParticipant', userId

    ###*
     * Action to remove a participant to collaboration channel.
     *
     * @state 'ready'
     * @nextState 'uninitialized'
     * @via 'busy'
    ###
    removeParticipant: (userId) -> @handle 'removeParticipant', userId

    ###*
     * Initiate a social channel.
     *
     * @api private
     * @param {object=} callbacks
     * @param {function=} callbacks.success - success callback
     * @param {function=} callbacks.error   - error calback
    ###
    _initChannel: (callbacks = {}) ->
      initChannel (err, channel) =>
        return callback.error()  if err
        @channel = channel
        callbacks.success()
        @emit 'ChannelReady', { channel }


    ###*
     * Destroy a social channel.
     *
     * @api private
     * @param {object=} callbacks
     * @param {function=} callbacks.success - success callback
     * @param {function=} callbacks.error   - error calback
    ###
    _destroyChannel: (callbacks) ->
      destroyChannel @channel, (err) =>
        return callbacks.error()  if err
        @channel = null
        callbacks.success()
        @emit 'ChannelDeleted'

    ###*
     * Fetch social channel with given id.
     *
     * @api private
     * @param {string} id - channel id
     * @param {object=} callbacks
     * @param {function=} callbacks.success - success callback
     * @param {function=} callbacks.error   - error calback
    ###
    _fetchChannel: (id, callbacks) ->
      fetchChannel id, (err, channel) =>
        return callbacks.error err  if err
        @channel = channel
        callbacks.success()
        @emit 'ChannelReady', { channel }


    ###*
     * Add user with given id as participant.
     *
     * @api private
     * @param {string} userId
     * @param {object=} callbacks
     * @param {function=} callbacks.success - success callback
     * @param {function=} callbacks.error   - error calback
    ###
    _addParticipant: (userId, callbacks) ->
      getAccount userId, (err, account) =>
        return handleError err  if err
        opts = { channelId: @channel.id, accountIds: [account.socialApiId] }
        addParticipants opts, (err) =>
          return callbacks.error err  if err
          callbacks.success account
          @emit 'ParticipantAdded', { account }


    ###*
     * Remove participant with given user id.
     *
     * @api private
     * @param {object=} callbacks
     * @param {function=} callbacks.success - success callback
     * @param {function=} callbacks.error   - error calback
    ###
    _removeParticipant: (userId, callbacks) ->
      getAccount userId, (err, account) =>
        return callbacks.error err  if err
        opts = { channelId: @channel.id, accountIds: [account.socialApiId] }
        removeParticipants opts, (err) =>
          return callbacks.error err  if err
          callbacks.success()
          @emit 'ParticipantRemoved', { id: userId }

  return channelMachine

###*
 * Following are convenient functions to wrap
 * socialapicontroller calls.
 * Since those are stateless functions,
 * tried to use those to keep public api as clean as possible. ~Umut
###
addParticipants = (opts, callback) ->
  kd.singletons.socialapi.channel.addParticipants opts, callback

removeParticipants = (opts, callback) ->
  kd.singletons.socialapi.channel.removeParticipants opts, callback

fetchChannel = (id, callback) ->
  kd.singletons.socialapi.cacheable 'channel', id, callback

destroyChannel = (channel, callback) ->
  {id} = channel
  kd.singletons.socialapi.channel.delete {channelId: id}, callback

initChannel = (callback) ->
  {message} = kd.singletons.socialapi
  nickname  = getNick()

  options =
    type       : 'collaboration'
    body       : "@#{nickname} initiated the IDE session."
    recipients : [ nickname ]
    payload    : {'system-message': 'initiate'}

  message.initPrivateMessage options, (err, channels) ->
    return callback err  if err
    return callback {message: 'error'}  unless channels?.length
    return callback null, channels[0]

getAccount = (userId, callback) ->
  remote.cacheable 'JAccount', userId, callback

handleError = (err) ->
  throw new Error "ChannelStateMachine: #{err.message}"

module.exports = { create }
