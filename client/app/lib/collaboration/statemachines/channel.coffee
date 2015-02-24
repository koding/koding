machina = require 'machina'
kd      = require 'kd'
getNick = require 'app/util/nick'

remote = require('app/remote').getInstance()

create = (channelId) ->

  channelMachine = new machina.Fsm
    initialState: 'loading'
    states:
      ###*
       * Initial decide state.
       *
       * It will:
       * - fetch the channel with given id if `channelId` is present.
       * or
       * - switch state to 'uninitialized' if no `channelId` is present.
      ###
      loading:
        _onEnter: ->
          if channelId
          then @_fetchChannel channelId
          else @transition 'uninitialized'

        '*': -> @deferUntilTransition()

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
          @makeBusy => @_initChannel()

        '*': -> @deferUntilTransition()

      ###*
       * State to indicate that collaboration channel
       * instance is ready for action.
      ####
      ready:
        terminate: ->
          @makeBusy => @_destroyChannel()

        addParticipant: (userId) ->
          @makeBusy => @_addParticipant userId

        removeParticipant: (userId) ->
          @makeBusy => @_removeParticipant userId

        '*': ->
          @deferUntilTransition()
          @transition 'busy'

      ###*
       * State to indicate that there is some operation happening.
      ###
      busy:
        channelDeleted: 'loading'
        # following could be written as
        # '*': 'ready'
        # keeping them here for clarity. ~Umut
        channelReady: 'ready'
        participantAdded: 'ready'
        participantRemoved: 'ready'

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
     * Puts machine into `busy` state and executes the callback.
     *
     * @param {function=} callback
    ####
    makeBusy: (callback) ->
      @transition 'busy'
      callback?()

    ###*
     * Initiate a social channel.
     *
     * @emits 'ChannelReady'
     * @successAction 'channelReady'
     * @nextState 'ready'
     *
     * @api private
    ###
    _initChannel: ->
      initChannel (err, channel) =>
        return handleError err  if err
        @channel = channel
        @handle 'channelReady'
        @emit 'ChannelReady', { channel }


    ###*
     * Destroy a social channel.
     *
     * @emits 'ChannelDeleted'
     * @successAction 'channelDeleted'
     * @nextState 'uninitialized'
     *
     * @api private
    ###
    _destroyChannel: ->
      destroyChannel @channel, (err) =>
        return handleError err  if err
        @channel = null
        @handle 'channelDeleted'
        @emit 'ChannelDeleted'


    ###*
     * Fetch social channel with given id.
     *
     * @emits 'ChannelReady'
     * @successAction 'channelReady'
     * @nextState 'ready'
     *
     * @api private
     *
     * @param {string} id - channel id
    ###
    _fetchChannel: (id) ->
      fetchChannel id, (err, channel) =>
        return handleError err  if err
        @channel = channel
        @handle 'channelReady'
        @emit 'ChannelReady', { channel }


    ###*
     * Add user with given id as participant.
     *
     * @emits 'ParticipantAdded'
     * @successAction 'participantAdded'
     * @nextState 'ready'
     *
     * @api private
     *
     * @param {string} userId
    ###
    _addParticipant: (userId) ->
      getAccount userId, (err, account) =>
        return handleError err  if err
        opts = { channelId: @channel.id, accountIds: [account.socialApiId] }
        addParticipants opts, (err) =>
          return handleError err  if err
          @channel.emit 'AddedToChannel', account
          @handle 'participantAdded'
          @emit 'ParticipantAdded', { account }


    ###*
     * Remove participant with given user id.
     *
     * @emits 'ParticipantRemoved'
     * @successAction 'participantRemoved'
     * @nextState 'ready'
     *
     * @api private
     *
     * @param {string} userId
    ###
    _removeParticipant: (userId) ->
      getAccount userId, (err, account) =>
        return handleError err  if err
        opts = { channelId: @channel.id, accountIds: [userId] }
        removeParticipants opts, (err) =>
          return handleError err  if err
          @channel.emit 'RemovedFromChannel', account
          @handle 'participantRemoved'
          @emit 'ParticipantRemoved', { id: userId }

  return channelMachine

###*
 * Following are convinient functions to wrap
 * socialapicontroller calls.
 * Since because those are stateless functions,
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
