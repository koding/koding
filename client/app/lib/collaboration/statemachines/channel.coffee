machina = require 'machina'
kd      = require 'kd'
getNick = require 'app/util/nick'
_       = require 'lodash'

remote = require('app/remote').getInstance()

create = (channelId) ->

  channelMachine = new machina.Fsm
    initialState: 'loading'

    constraints:
      loading:
        nextState: 'uninitialized'
        checkList: { ready: no }

      uninitialized:
        nextState: 'active'
        checkList: { active: no }

      activating:
        nextState: 'active'
        checkList: { active: no }

      terminating:
        nextState: 'terminated'
        checkList: { terminated: no }

    states:
      loading:
        _onEnter : ->
          @constraints.loading.checkList.ready = yes
          @nextIfReady()
        _onExit  : ->
          @emit 'LoadingFinished'

      uninitialized:
        _onEnter          : -> @_fetchChannel channelId
        channelFound      : ->
          @constraints.uninitialized.checkList.active = yes
          @nextIfReady()
        fetchChannelError : (error) -> handleError error

        activate: -> @transition 'activating'

      activating:
        _onEnter         : -> @_initChannel()
        channelActive    : ->
          @constraints.activating.checkList.active = yes
          @nextIfReady()
        initChannelError : (error) -> handleError error

      active:
        _onEnter  : -> @emit 'ChannelReady', { @channel }
        terminate : -> @transition 'terminating'

        addParticipant: (userId) ->
          @transition 'busy'
          @_addParticipant userId

        removeParticipant: (userId) ->
          @transition 'busy'
          @_removeParticipant userId

      terminating:
        _onEnter            : -> @_destroyChannel()
        channelDestroyed    : ->
          @constraints.terminating.checkList.terminated = yes
          @nextIfReady()
        destroyChannelError : (error) -> handleError error

      terminated:
        _onEnter: -> @emit 'ChannelTerminated'

      busy:
        participantAdded   : (participant) ->
          @emit 'ParticipantAdded', { participant }
          @transition 'active'

        participantRemoved : (participant) ->
          @emit 'ParticipantRemoved', { participant }
          @transition 'active'

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
    ###
    init: -> @handle 'init'

    ###*
     * Action to terminate a collaboration channel.
    ###
    terminate: -> @handle 'terminate'

    ###*
     * Action to add a participant to collaboration channel.
    ###
    addParticipant: (userId) -> @handle 'addParticipant', userId

    ###*
     * Action to remove a participant to collaboration channel.
    ###
    removeParticipant: (userId) -> @handle 'removeParticipant', userId

    nextIfReady: ->
      constraint = @constraints[@state]
      ready = _.all constraint.checkList, (checkItem) =>
        checkItem = checkItem()  if 'function' is typeof checkItem
        return checkItem
      @transition constraint.nextState  if ready

    ###*
     * Initiate a social channel.
     *
     * @api private
    ###
    _initChannel: ->
      initChannel (err, channel) =>
        return @handle 'initChannelError', err  if err
        @channel = channel
        @handle 'channelActive', channel


    ###*
     * Destroy a social channel.
     *
     * @api private
    ###
    _destroyChannel: ->
      destroyChannel @channel, (err) =>
        return @handle 'destroyChannelError', err  if err
        @channel = null
        channelId = null
        @handle 'channelDestroyed'

    ###*
     * Fetch social channel with given id.
     *
     * @api private
     * @param {string} id - channel id
    ###
    _fetchChannel: (id) ->
      fetchChannel id, (err, channel) =>
        return @handle 'fetchChannelError', err  if err
        @channel = channel
        @handle 'channelFound', @channel


    ###*
     * Add user with given id as participant.
     *
     * @api private
     * @param {string} userId
    ###
    _addParticipant: (userId) ->
      fetchAccount userId, (err, account) =>
        return @handle 'addParticipantError', err  if err
        opts = { channelId: @channel.id, accountIds: [account.socialApiId] }
        addParticipants opts, (err) =>
          return @handle 'addParticipantError', err  if err
          @handle 'participantAdded', account


    ###*
     * Remove participant with given user id.
     *
     * @api private
    ###
    _removeParticipant: (userId) ->
      fetchAccount userId, (err, account) =>
        return @handle 'removeParticipantError', err  if err
        opts = { channelId: @channel.id, accountIds: [account.socialApiId] }
        removeParticipants opts, (err) =>
          return @handle 'removeParticipantError', err  if err
          @handle 'participantRemoved', account

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

fetchAccount = (userId, callback) ->
  remote.cacheable 'JAccount', userId, callback

handleError = (err) ->
  throw new Error "ChannelStateMachine: #{err.message}"

module.exports = { create }
