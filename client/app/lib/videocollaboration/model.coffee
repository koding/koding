kd              = require 'kd'
_               = require 'lodash'
getNick         = require 'app/util/nick'

OpenTokService  = require './services/opentok'
ParticipantType = require './types/participant'
ViewModel       = require './viewmodel'
helper          = require './helper'

module.exports = class VideoCollaborationModel extends kd.Object

  defaultState:
    publishVideo       : on
    publishAudio       : on
    publishing         : off
    active             : no
    connected          : no
    maxConnectionCount : 999
    activeParticipant  : null
    connectionCount    : 0

  # @param {SocialChannel} options.channel
  # @param {BaseChatVideoView} options.view
  constructor: (options = {}, data) ->

    super options, data

    @state = _.assign {}, options.state, @defaultState

    { @channel, @view } = options

    @session     = null
    @publisher   = null
    @stream      = null
    @subscribers = {}

    # attach this model and the view into a view model, it can track the model
    # for necessary events and reacts to it.
    @_videoModel = new ViewModel { @view, model: this }

    # instantiate the service and when it's ready, start this model's
    # intitalization process.
    @_service = OpenTokService.getInstance()
    @_service.whenReady @bound 'init'


  ###*
   * Returns the view.
   *
   * @return {KDView} view
  ###
  getView: -> @view


  ###*
   * Returns the channel.
   *
   * @return {SocialChannel} channel
  ###
  getChannel: -> @channel


  ###*
   * Connects to service, then delegates to necessary method.
   *
   * TODO: Error Handling.
  ###
  init: ->

    @_service.connect @channel,
      success : @bound 'handleSessionConnected'
      error   : (err) =>


  ###*
   * Handler for session connected.
   * Binds the session, session events and updates the state.
   *
   * @param {OT.Session} session
   * @emits VideoCollaborationModel~SessionConnected
  ###
  handleSessionConnected: (session) ->

    @session = session
    @bindSessionEvents session
    @setState { connected: yes }
    @emit 'SessionConnected', session


  ###*
   * Registers callbacks for service events.
   *
   * @param {OT.Session} session
   * @listens OT.Session~streamCreated
   * @listens OT.Session~streamDestroyed
   * @listens OT.Session~connectionCreated
   * @listens OT.Session~sessionDisconnected
   * @emits VideoCollaborationModel~HostKickedLoggedInUser
   * @emits VideoCollaborationModel~VideoCollaborationEnded
   * @emits VideoCollaborationModel~VideoCollaborationEndedByNetwork
  ###
  bindSessionEvents: (session) ->

    session.on 'streamCreated', (event) =>
      # When a stream is dispatched to the session it means there is a new
      # video feed. We want every user to see the video if a stream is
      # dispatched (probably from host, but doesn't matter).
      @setActive()  unless @state.active

      options    = { height: '100%', width: '100%', insertMode: 'append' }
      { stream } = event
      nick       = stream.name
      element    = @getView().getElement()

      { connectionId } = stream.connection

      subscriber = session.subscribe stream, element, options
      participant = @registerSubscriber nick, connectionId, subscriber

      @emit 'ParticipantJoined', participant

    session.on 'streamDestroyed', (event) =>

      @emit 'ParticipantLeft', { nick: event.stream.name }

    session.on 'connectionCreated', (event) =>
      count = @state.connectionCount
      @setState { connectionCount: count + 1 }

    session.on 'connectionDestroyed', (event) =>
      count = @state.connectionCount
      @setState { connectionCount: count - 1 }

    session.on 'sessionDisconnected', (event) =>
      @setState { connected: no }
      eventName = switch event.reason
        when 'forceDisconnected'   then 'HostKickedLoggedInUser'
        when 'clientDisconnected'  then 'VideoCollaborationEnded'
        when 'networkDisconnected' then 'VideoCollaborationEndedByNetwork'

      @emit eventName


  ###*
   * Creates a `ParticipantType.Subscriber` instance and it caches it with `connectionId`
   * into `subscribers` map.
   *
   * @param {string} nick
   * @param {string} connectionId
   * @param {OT.Subscriber} subscriber
   * @return {ParticipantType.Subscriber} _subscriber
  ###
  registerSubscriber: (nick, connectionId, subscriber) ->

    _subscriber = new ParticipantType.Subscriber nick, subscriber
    @subscribers[connectionId] = _subscriber

    return _subscriber


  ###*
   * Unregisters the subscriber from `subscribers` map.
   *
   * @param {strong} connectionId
  ###
  unregisterSubscriber: (connectionId) ->

    delete @subscribers[connectionId]


  ###*
   * Transforms given publisher instance from OpenTok into our own
   * `ParticipantType.Publishe` class instance and it registers it into model's
   * participant property.. It sets the model's stream instance to publisher's
   * stream for easy access.
   *
   * @param {OT.Publisher} publisher
   * @return {ParticipantType.Publisher} _publisher
  ###
  registerPublisher: (publisher) ->

    @publisher = _publisher = new ParticipantType.Publisher getNick(), publisher
    @stream    = _publisher.stream

    return _publisher


  ###*
   * Action to trigger activation of video collaboration.
   * If given publisher is `null` it means that the video collaboration started
   * without the user publishing his/her video. It's not a concern of neither
   * this method's nor this entire class, because simply it will emit an event
   * with given publisher and it will change set the state to active.
   * This method doesn't try to activate session, instead this is the final
   * step of activation of video collaboration session.
   *
   * @emits VideoCollaborationModel~VideoCollaborationActive
  ###
  setActive: ->
    return  if @state.active

    @emit 'VideoCollaborationActive', @publisher
    @setState { active: yes }


  ###*
   * Action to trigger ending process of video collaboration.
   * !!! It doesn't stop the session itself, this and other methods starting
   * with `set` prefix are meant to be called to trigger events for views and
   * state transitions. This is the final step of ending a session.
   *
   * @emits VideoCollaborationModel~VideoCollaborationEnded
  ###
  setEnded: ->
    return  unless @state.active

    @emit 'VideoCollaborationEnded'
    @setState { active: no }


  ###*
   * Registers given OT.Subscriber to subscribers object. It gets the necessary
   * connectionId information from subscriber object.
   *
   * @param {string} nick
   * @param {OT.Subscriber} subscriber
   * @return {ParticipantType.Subscriber} _participant
   * @emits VideoCollaborationModel~ParticipantJoined
  ###
  setParticipantJoined: (nick, subscriber) ->

    { connectionId } = subscriber.stream.connection
    _participant = @registerSubscriber nick, connectionId, subscriber
    @emit 'ParticipantJoined', _participant

    return _participant


  ###*
   * Unregisters participant from subscribers object.
   * It uses given connectionId to do this.
   *
   * @param {string} connectionId - participant's stream's connection id.
   * @return {ParticipantType.Subscriber} _participant
   * @emits VideoCollaborationModel~ParticipantLeft
  ###
  setParticipantLeft: (connectionId) ->

    _participant = @subscribers[connectionId]
    @unregisterSubscriber connectionId

    @emit 'ParticipantLeft', { nick: _participant.nick }

    return _participant


  ###*
   * Action for starting VideoCollaboration session. It calls
   * `startPublishing` method and connects handlers for success and error states.
   *
   * @param {object} options
  ###
  start: (options) ->

    @startPublishing options,
      success : @bound 'handlePublishSuccess'
      error   : (err) =>


  ###*
   * Action for ending VideoCollaborationSession. Only can be called from
   * admins of this session.
  ###
  end: ->

    @stopSession
      success : @bound 'handleStopSuccess'
      error   : (err) =>


  ###*
   * Handler for successful video publishing. It transforms and registers given
   * `OT.Publisher` instance. Sets active participant to user.
   *
   * @param {OT.Publisher} publisher
  ###
  handlePublishSuccess: (publisher) ->

    @registerPublisher publisher
    @setState { publishing: on }

    @setActive()
    @changeActiveParticipant getNick()


  ###*
   * Handler for successful video stopping.
  ###
  handleStopSuccess: ->

    @setState { publishing: off }
    @setEnded()


  ###*
   * Starts publishing. It enables video and audio depending on the state
   * variables. That extension over state with given options object provides a
   * convinient way to extend the defaults to be passed into service. It can be
   * forced to open video or audio with options.
   *
   * @param {object} options
   * @param {boolean} options.publishAudio
   * @param {boolean} options.publishVideo
   * @param {function(publisher: OT.Publisher)} callbacks.success
   * @param {function(error: object)} callbacks.error
  ###
  startPublishing: (options, callbacks) ->

    defaults =
      publishAudio: @state.publishAudio
      publishVideo: @state.publishVideo

    options = _.assign {}, defaults, options

    @_service.createPublisher @view, options, (err, publisher) =>
      return callbacks.error err  if err

      publisher.on
        accessAllowed      : => @emit 'CameraAccessAllowed'
        accessDenied       : => @emit 'CameraAccessDenied'
        accessDialogOpened : => @emit 'CameraAccessQuestionAsked'
        accessDialogClosed : => @emit 'CameraAccessQuestionAnswered'

      @session.publish publisher, (err) =>
        if err
        then callbacks.error err
        else callbacks.success publisher


  ###*
   * It delegates to necessary methods from service to stop session, and then
   * calls given callbacks in certain situations.
   *
   * @param {function(err: object)} callbacks.error
   * @param {function} callbacks.success
  ###
  stopSession: (callbacks) ->

    @_service.sendSessionEndSignal @channel, (err) =>
      return callbacks.error err  if err
      @_service.destroyPublisher @channel, @publisher, (err) =>
        return callbacks.error err  if err
        callbacks.success()


  ###*
   * Changes active user defensively.
   *
   * @param {string} nick
   * @emits VideoCollaboration~ActiveParticipantChanged
  ####
  changeActiveParticipant: (nick) ->

    return  unless @state.active
    return  unless @getParticipant nick

    @setState { activeParticipant: nick }
    @emit 'ActiveParticipantChanged', nick


  ###*
   * Public access method for all participants. Just because internally the
   * subscribers are cached with `connectionId` instead of `nickname`s of
   * subscribers/publisher, we are first transforming the subscribers and merge
   * it with publisher instance to create a unified subscribers/publisher map.
   *
   * @return {object<nickname: string, ParticipantType.Participant>} participants
  ###
  getParticipants: -> helper.toNickKeyedMap @subscribers, @publisher


  ###*
   * Return `ParticipantType.Participant` instance of participant with given nickname.
   *
   * @param {string} nick
   * @return {ParticipantType.Participant} participant
  ###
  getParticipant: (nick) -> @getParticipants()[nick]


  ###*
   * Merges instance state with given state.
   *
   * @param {object} _state
   * @return {object} state
  ###
  setState: (state) -> @state = _.assign {}, @state, state


  getSubscribersCount: -> (Object.keys @subscribers).length


