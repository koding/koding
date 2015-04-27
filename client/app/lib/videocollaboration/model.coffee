kd              = require 'kd'
_               = require 'lodash'
getNick         = require 'app/util/nick'
isMyChannel     = require 'app/util/isMyChannel'

OpenTokService  = require './services/opentok'
ParticipantType = require './types/participant'
ViewModel       = require './viewmodel'
helper          = require './helper'

module.exports = class VideoCollaborationModel extends kd.Object

  defaultState:
    audio               : off
    video               : off
    publishing          : off
    active              : no
    connected           : no
    maxConnectionCount  : 999
    activeParticipant   : null
    selectedParticipant : null
    connectionCount     : 0

  # @param {SocialChannel} options.channel
  # @param {BaseChatVideoView} options.view
  constructor: (options = {}, data) ->

    super options, data

    @state = _.assign {}, @defaultState, options.state

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


  isMySession: -> isMyChannel @channel


  ###*
   * Connects to service, then delegates to necessary method.
   *
   * TODO: Error Handling.
  ###
  init: ->

    @_service.connect @channel,
      success : @bound 'handleSessionConnected'
      error   : (err) -> console.error err


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

    @enableVideo { error: (err) => console.error err }  if helper.isVideoActive @channel


  ###*
   * Registers callbacks for service events.
   *
   * @param {OT.Session} session
   * @emits VideoCollaborationModel~HostKickedLoggedInUser
   * @emits VideoCollaborationModel~VideoCollaborationEnded
   * @emits VideoCollaborationModel~VideoCollaborationEndedByNetwork
  ###
  bindSessionEvents: (session) ->

    session.on 'connectionCreated'   , @bound 'onConnectionCreated'
    session.on 'streamCreated'       , @bound 'onStreamCreated'
    session.on 'streamDestroyed'     , @bound 'onStreamDestroyed'
    session.on 'connectionDestroyed' , @bound 'onConnectionDestroyed'

    session.on 'sessionDisconnected', (event) =>
      @setState { connected: no }
      eventName = switch event.reason
        when 'forceDisconnected'   then 'HostKickedLoggedInUser'
        when 'clientDisconnected'  then 'VideoCollaborationEnded'
        when 'networkDisconnected' then 'VideoCollaborationEndedByNetwork'

      @emit eventName

    session.on 'signal:end', =>
      # when a signal comes here it means that it could have reached to other
      # users and because of that at this stack we may have extra
      # `streamDestroyed` events. Since stopPublishing will trigger the events
      # that eventually nullify the publisher in this stack, this defer tries
      # to overcome that problem. ~Umut
      kd.utils.defer => @stopPublishing
        success : @bound 'handleStopSuccess'
        error   : (err) -> console.error err

    session.on 'signal:start', => @enableVideo { error: (err) => console.error err }

    # this event only comes to the user who has been muted, so need to make a
    # filtering here.
    session.on 'signal:mute', => @setAudioState off


  ###*
   * Opentok session's `connectionCreated` event handler.
   *
   * @param {OT.ConnectionEvent} event
   * @emits VideoCollaborationModel~ParticipantConnected
  ###
  onConnectionCreated: (event) ->
    # We don't want to deal with own user's events, we basically want to
    # abstract out logged-in user out of the equation here.
    return  if @isMyConnection event.connection

    # this is gonna be a fake `ParticipantType.Subscriber` like object for
    # views to start drawing/rendering for this connection, because our
    # system doesn't necessarily require people to be publishint to session
    # to mark them as active. For example, showing participant heads on ide
    # chat window when video active we are filtering people who are connected
    # to session as actives. Participant heads doesn't care if you are
    # publishing or not, since user is hearing the video and seeing other
    # users he/she needs to be labeled as active/connected.
    subscriber = @registerDefaultSubscriber event.connection

    @incrementConnectionCount()

    @emit 'ParticipantConnected', subscriber


  ###*
   * Opentok session's `connectionCreated` event handler.
   *
   * @param {OT.ConnectionEvent} event
   * @emits VideoCollaborationModel~ParticipantDisconnected
  ###
  onConnectionDestroyed: (event) ->

    { connection } = event

    return  if @isMyConnection connection

    @setParticipantLeft connection.id
    @decrementConnectionCount()

    nick = helper.getNicknameFromConnection connection

    @emit 'ParticipantDisconnected', helper.defaultSubscriber nick


  ###*
   * Opentok session's `streamCreated` event handler.
   *
   * @param {OT.StreamEvent} event
  ###
  onStreamCreated: (event)->

    @subscribeToStream session, event.stream


  ###*
   * Opentok session's `streamDestroyed` event handler.
   *
   * @param {OT.StreamEvent} event
  ###
  onStreamDestroyed: (event) ->
    { connection } = event.stream
    @setParticipantLeft connection.connectionId


  ###*
   * Subscribes to given session's given stream.
   *
   * It uses helper method to subscribe, it's success callback will return the
   * `OT.Subscriber` object. From that on, the conversion from `OT.Subscriber`
   * to `ParticipantType.Subscriber` and other jobs happen in success handler.
   *
   * @param {OT.Session} session
   * @param {OT.Stream} stream
  ###
  subscribeToStream: (session, stream) ->

    helper.subscribeToStream session, stream, @getView().getContainer(),
      success : (subscriber) => @setParticipantJoined stream.name, subscriber
      error   : (err) -> console.error err


  ###*
   * Initial call to startPublishing method. `startPublishing` is stateless.
   * This method handles initial automatic publishing with setting some default
   * options for host, and participant to be different.
   *
   * @param {object} callbacks
  ###
  enableVideo: (callbacks) ->

    @setActive()

    success = (publisher) =>
      @handlePublishSuccess publisher
      callbacks.success? publisher

    options = { publishAudio: @isMySession(), publishVideo: @isMySession() }
    @startPublishing options,
      success : success
      error   : callbacks.error


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

    _subscriber.on 'TalkingDidStart', =>
      @emit 'ParticipantStartedTalking', nick
      @changeActiveParticipant nick  unless @state.selectedParticipant

    _subscriber.on 'TalkingDidStop', =>
      @emit 'ParticipantStoppedTalking', nick

    return _subscriber


  ###*
   * Unregisters the subscriber from `subscribers` map.
   *
   * @param {strong} connectionId
  ###
  unregisterSubscriber: (connectionId) -> @subscribers[connectionId] = null


  ###*
   * Parse the username from given connection and add a default subscriber
   * without video to trigger view updates.
   *
   * @param {OT.Connection} connection
   * @return {(undefined|object)}
  ###
  registerDefaultSubscriber: (connection) ->

    { id, data } = connection
    { nickname } = JSON.parse data

    return  if nickname is getNick()

    _subscriber = helper.defaultSubscriber nickname

    @subscribers[id] = _subscriber

    return _subscriber


  ###*
   * Transforms given publisher instance from OpenTok into our own
   * `ParticipantType.Publisher` class instance and it registers it into model's
   * participant property.. It sets the model's stream instance to publisher's
   * stream for easy access.
   *
   * @param {OT.Publisher} publisher
   * @return {ParticipantType.Publisher} _publisher
  ###
  registerPublisher: (publisher) ->

    @publisher = _publisher = new ParticipantType.Publisher getNick(), publisher
    @stream    = _publisher.stream

    _publisher.on 'TalkingDidStart', =>
      return  unless @state.audio
      @emit 'ParticipantStartedTalking', getNick()

    _publisher.on 'TalkingDidStop', =>
      return  unless @state.active
      @emit 'ParticipantStoppedTalking', getNick()

    return _publisher


  ###*
   * Unregister publisher and stream.
  ###
  unregisterPublisher: ->

    @publisher = null
    @stream = null


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

    @setState { active: yes }
    @emit 'VideoCollaborationActive', @publisher


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

    @setState { active: no }
    @emit 'VideoCollaborationEnded'


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

    return  unless _participant = @subscribers[connectionId]
    @unregisterSubscriber connectionId

    { nick } = _participant
    @emit 'ParticipantLeft', helper.defaultSubscriber nick

    # if leaving participant is selected or active participant
    if @state.activeParticipant is nick
      @changeActiveParticipant getNick()
      if @state.selectedParticipant is nick
        @setSelectedParticipant null

    return _participant


  ###*
   * Action for starting VideoCollaboration session.
   *
   * @param {object} options
  ###
  start: (options) ->

    helper.enableVideo @channel, (err) =>
      return console.error err  if err
      @_service.sendSessionStartSignal @channel, (err) ->
        return console.error err  if err


  ###*
   * Action for ending VideoCollaborationSession. Only can be called from
   * admins of this session.
  ###
  end: ->

    helper.disableVideo @channel, (err) =>
      return console.error err  if err
      @_service.sendSessionEndSignal @channel, (err) ->
        return console.error err  if err


  ###*
   * Action for muting a participant. Sends the signal, the rest will be
   * handled by the `signal:mute` handler.
   *
   * @param {string} nickname
  ###
  muteParticipant: (nickname) ->

    return  unless participant = @getParticipant nickname

    @_service.sendMuteSignal @channel, participant, (err) ->
      return console.log err  if err


  ###*
   * Set audio state to given state.
   *
   * @param {boolean} state
  ###
  setAudioState: (state) ->

    @publisher.videoData.publishAudio state
    @setState { audio: state }
    @emit 'AudioPublishStateChanged', state


  ###*
   * Set video state to given state.
   *
   * @param {boolean} state
  ###
  setVideoState: (state) ->

    @publisher.videoData.publishVideo state
    @setState { video: state }
    @emit 'VideoPublishStateChanged', state


  ###*
   * Handler for successful video publishing. It transforms and registers given
   * `OT.Publisher` instance. Sets active participant to user.
   *
   * @param {OT.Publisher} publisher
  ###
  handlePublishSuccess: (publisher) ->

    @registerPublisher publisher
    @setState { publishing: on }

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
    return  if @state.publishing

    defaults =
      publishAudio: no
      publishVideo: no

    # first create publisher with defaults.
    helper.createPublisher @view.getContainer(), defaults, (err, publisher) =>
      return callbacks.error err  if err

      publisher.on
        accessAllowed      : => @emit 'CameraAccessAllowed'
        accessDenied       : => @emit 'CameraAccessDenied'
        accessDialogOpened : => @emit 'CameraAccessQuestionAsked'
        accessDialogClosed : => @emit 'CameraAccessQuestionAnswered'

      publisher.on 'streamDestroyed', => @unregisterPublisher()

      @session.publish publisher, (err) =>
        return callbacks.error err  if err
        callbacks.success publisher
        @setAudioState options.publishAudio
        @setVideoState options.publishVideo


  ###*
   * It delegates to necessary methods from service to stop session, and then
   * calls given callbacks in certain situations.
   *
   * @param {function(err: object)} callbacks.error
   * @param {function} callbacks.success
  ###
  stopPublishing: (callbacks) ->

    @_service.destroyPublisher @channel, @publisher, (err) ->
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
    return  unless @isParticipantOnline nick

    @setState { activeParticipant: nick }

    @emit 'ActiveParticipantChanged', nick


  ###*
   * Change both active and selected users. It's being used for locking
   * selected participant's video so that automatic video switching (e.g Audio
   * level changed) could be prevented.
   *
   * @param {string} nick
  ###
  changeSelectedParticipant: (nick) ->

    @setSelectedParticipant nick
    @changeActiveParticipant nick


  ###*
   * Sets state's selected participant to given nick. If nick is null, that
   * means that user is clicked twice.
   *
   * @param {string} nick
  ###
  setSelectedParticipant: (nick) ->

    unless isOnline = @isParticipantOnline nick
      @emit 'SelectedParticipantChanged', nick, no
      return

    nick = null  if @state.selectedParticipant is nick

    @setState { selectedParticipant: nick }
    @emit 'SelectedParticipantChanged', nick, yes


  ###*
   * @param {string} nickname
   * @return {boolean}
  ###
  isParticipantOnline: (nickname) -> @getParticipant(nickname)?


  ###*
   * @param {OT.Connection} connection
   * @return {boolean}
  ###
  isMyConnection: (connection) ->

    nickname = helper.getNicknameFromConnection connection

    return nickname is getNick()


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


  ###*
   * Set state to increment connection count.
  ###
  incrementConnectionCount: ->

    @setState { connectionCount: @state.connectionCount + 1 }


  ###*
   * Set state to decrement connection count.
  ###
  decrementConnectionCount: ->

    @setState { connectionCount: @state.connectionCount - 1 }


  ###*
   * Check to see if participant with given nickname, and calls the callback
   * with result.
   *
   * @param {string} nickname
   * @param {function(hasAudio: boolean)} callback
  ###
  hasParticipantWithAudio: (nickname, callback) ->
    return callback no  unless @state.active

    if participant = @getParticipant nickname
    then callback participant.videoData.stream.hasAudio
    else callback no


