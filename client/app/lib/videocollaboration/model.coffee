kd              = require 'kd'
_               = require 'lodash'
getNick         = require 'app/util/nick'
isMyChannel     = require 'app/util/isMyChannel'

OpenTokService  = require './services/opentok'
ParticipantType = require './types/participant'
ViewModel       = require './viewmodel'
helper          = require './helper'
constants       = require './constants'

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

    if helper.isVideoActive @channel
      @setActive()

      if @isMySession()
        @enableVideo {},
          success: =>
            @setVideoState yes
            @setAudioState yes


  ###*
   * Convinience method for requesting camera and microphone access
   * sequentially for host. Accepts an option callback to be called after both
   * devices are activated.
   *
   * @param {function=} callback
  ###
  requestVideoPublishForHost: (callback) ->

    # these next 2 calls both requires this model to be in the publishing
    # state to make operations, IF the state is NOT publishing at the moment.
    # However, if we call then syncronously the calls will be sequential and
    # both method will try to open the camera. That's why we are using
    # `requestVideoStateChange` method's callback to make sure that audio
    # request change will not trigger any other publisher creation process.
    # The same exact call is happening at first reload if video is active.
    @requestVideoStateChange on, =>
      @requestAudioStateChange on
      callback?()


  ###*
   * Because we are alternating 2 different types of publishers that are
   * `video-disabled` and `video-enabled` this method will handle that logic.
   * Publishing mechanism is being controlled by here.
   *
   * This method's responsibilities are somehow mixed:
   *
   *   - It just enables (starts publishing) the video chat and calls the optional callback.
   *   - If it's already being published,
   *     - it first unpublishes the current publisher.
   *     - then creates a new publisher that is either `video-enabled` or `video-enabled`
   *       publishes that to the session.
   *     - updates the publisher's video data.
   *     - then updates the video state of the model.
   *
   * TODO: this method needs some after thinking. ~Umut
   *
   * @param {boolean} videoState
   * @param {function=} callback - this will be callled after video state update is done.
  ###
  requestVideoStateChange: (videoState, callback) ->

    # this options are required for publishing functions.
    options = getCameraOptionFromState videoState

    oldVideoState = @state.video

    if @state.publishing
      # if we are trying to change video state to same state, just return
      return  if videoState is oldVideoState

      # this method will just unpublish from the session, will not make any
      # other update, or any mutation to recent state of model.
      @_unpublishFromSession =>
        @_createPublisher options, (err, videoData) =>
          # first update KodingPublisher's video data
          @publisher.setVideoData videoData
          # set video state to given state so that other views can react to it.
          @setVideoState videoState

          callback?()

    else
      # no need to unpublish, and at this state, we want all the other handlers
      # to work with `startPublishing` and so on. When the success callback is
      # called, the publisher will be ready with the necessary video data, so
      # no need to update its videoData here like we did before.
      @enableVideo options,
        error   : (err) -> console.error err
        success : =>
          @setVideoState videoState
          callback?()


  ###*
   * If it's already being published just sets state's audio to given state.
   * If not enables the video and then sets the state.
   *
   * @param {boolean} audioState
  ###
  requestAudioStateChange: (audioState) ->

    options = _.assign getCameraOptionFromState(@state.video),
      publishAudio : audioState

    oldAudioState = @state.audio

    if @state.publishing

      return  if audioState is oldAudioState

      @setAudioState audioState

    else
      @enableVideo options,
        error   : (err) -> console.error err
        success : @lazyBound 'setAudioState', audioState


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

    session.on 'signal:start', =>

      @setActive()

      if @isMySession()
        @enableVideo {},
          success: =>
            @setVideoState yes
            @setAudioState yes

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

    { connection } = event

    # We don't want to deal with own user's events, we basically want to
    # abstract out logged-in user out of the equation here.
    return  if @isMyConnection connection

    nick = helper.getNicknameFromConnection connection

    @setParticipantConnected nick, connection


  ###*
   * Opentok session's `connectionCreated` event handler.
   *
   * @param {OT.ConnectionEvent} event
   * @emits VideoCollaborationModel~ParticipantDisconnected
  ###
  onConnectionDestroyed: (event) ->

    { connection } = event

    return  if @isMyConnection connection

    @setParticipantDisconnected connection.id


  ###*
   * Opentok session's `streamCreated` event handler.
   *
   * @param {OT.StreamEvent} event
  ###
  onStreamCreated: (event) ->

    { stream } = event
    @subscribeToStream @session, stream,
      success : (subscriber) => @setParticipantJoined stream.name, subscriber
      error   : (err) -> console.error err


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
  subscribeToStream: (session, stream, callbacks) ->

    videoContainer = @view.getContainer()
    helper.subscribeToStream session, stream, videoContainer, callbacks


  ###*
   * Initial call to startPublishing method. `startPublishing` is stateless.
   * This method handles initial automatic publishing with setting some default
   * options for host, and participant to be different.
   *
   * @param {object} options
   * @param {object} callbacks
  ###
  enableVideo: (options, callbacks) ->

    success = (publisher) =>
      @handlePublishSuccess publisher
      callbacks.success? publisher

    @startPublishing options,
      success : success
      error   : callbacks.error


  ###*
   * Creates a `ParticipantType.Subscriber` instance and it caches it with
   * `connectionId` into `subscribers` map.
   *
   * @param {string} nick
   * @param {OT.Connection} connection
   * @return {ParticipantType.Subscriber} _subscriber
   * @emits VideoParticipantModel~ParticipantStartedTalking
   * @emits VideoParticipantModel~ParticipantStoppedTalking
  ###
  registerSubscriber: (nick, connection) ->

    _subscriber = new ParticipantType.Subscriber
      nick      : nick
      videoData : null
      status    : constants.PARTICIPANT_STATUS_OFFLINE

    @subscribers[connection.id] = _subscriber

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
   * @param {OT.Publisher} videoData
   * @return {ParticipantType.Publisher} _publisher
  ###
  registerPublisher: (videoData) ->

    @publisher = publisher = new ParticipantType.Publisher
      nick      : getNick()
      videoData : videoData
      status    : constants.PARTICIPANT_STATUS_PUBLISHING

    @stream = publisher.stream

    publisher.on 'TalkingDidStart', =>
      return  unless @state.audio
      @emit 'ParticipantStartedTalking', getNick()
      @changeActiveParticipant getNick()  unless @state.selectedParticipant

    publisher.on 'TalkingDidStop', =>
      return  unless @state.active
      @emit 'ParticipantStoppedTalking', getNick()

    return publisher


  ###*
   * Create the publisher with given options, and call given function.
   *
   * @param {object} options
   * @param {function} callback
  ###
  _createPublisher: (options = {}, callback) ->

    helper.createPublisher @view.getContainer(), options, (err, publisher) =>
      return callback err  if err

      publisher.on
        accessAllowed      : => @emit 'CameraAccessAllowed'
        accessDenied       : => @emit 'CameraAccessDenied'
        accessDialogOpened : => @emit 'CameraAccessQuestionAsked'
        accessDialogClosed : => @emit 'CameraAccessQuestionAnswered'

      # for some reason session's publish method's completion handler isn't
      # working consistent. However `accessAllowed` events are being dispatched
      # properly everytime a publisher is being published to session. Instead
      # of the completion handler of `session.publish` we are using this event.
      publisher.on 'accessAllowed', -> callback null, publisher

      @session.publish publisher


  ###*
   * Unpublishes current publisher from session, after that is destroyed, it
   * calls the callback. Tokbox, for some reason, requires a little time to be
   * passed doing something publisher related after current publisher is
   * destroyed. Magic number handles that. This method is necessary to work
   * with new publishers after destroying a publisher.
   *
   * @param {function} callback
  ###
  _unpublishFromSession: (callback) ->

    @publisher.videoData.once 'streamDestroyed', ->
      kd.utils.wait constants.NUMBER_THAT_MAKES_TOKBOX_WORK, callback

    @session.unpublish @publisher.videoData


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
   * @param {OT.Subscriber} videoData
   * @return {ParticipantType.Subscriber} _participant
   * @emits VideoCollaborationModel~ParticipantJoined
  ###
  setParticipantJoined: (nick, videoData) ->

    subscriber = @getParticipant nick

    # change subscriber's state to publishing.
    subscriber.setPublishing videoData

    @emit 'ParticipantJoined', subscriber

    return subscriber


  ###*
   * Unregisters participant from subscribers object.
   * It uses given connectionId to do this.
   *
   * @param {string} connectionId - participant's stream's connection id.
   * @return {ParticipantType.Subscriber} _participant
   * @emits VideoCollaborationModel~ParticipantLeft
  ###
  setParticipantLeft: (connectionId) ->

    return  unless subscriber = @subscribers[connectionId]

    # set subscriber's status back to `connected`, probably from `publishing`
    subscriber.setConnected()

    @emit 'ParticipantLeft', helper.defaultSubscriber subscriber.nick

    return subscriber


  setParticipantConnected: (nick, connection) ->

    subscriber = @registerSubscriber nick, connection

    @incrementConnectionCount()

    @emit 'ParticipantConnected', subscriber


  setParticipantDisconnected: (connectionId) ->

    return  unless subscriber = @subscribers[connectionId]

    if @state.activeParticipant is subscriber.nick
      @changeActiveParticipant getNick()

    if @state.selectedParticipant is subscriber.nick
      @setSelectedParticipant null

    @decrementConnectionCount()

    @unregisterSubscriber connectionId

    @emit 'ParticipantDisconnected', subscriber


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
      return console.error err  if err


  ###*
   * Set audio state to given state.
   *
   * @param {boolean} state
  ###
  setAudioState: (state) ->

    @ensurePublishing {}, =>
      @publisher.videoData.publishAudio state
      @setState { audio: state }
      @emit 'AudioPublishStateChanged', state


  ###*
   * Set video state to given state.
   *
   * @param {boolean} state
  ###
  setVideoState: (state) ->

    @ensurePublishing {}, =>
      @publisher.videoData.publishVideo state
      @setState { video: state }
      @emit 'VideoPublishStateChanged', state


  ensurePublishing: (options, callback) ->

    @setActive()

    if @state.publishing
    then callback @publisher
    else @enableVideo options, { success: callback }


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

    options = _.assign {}, defaults, options

    @_createPublisher options, (err, publisher) =>
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

    unless @isParticipantOnline nick
      @setState { selectedParticipant: null }
      @emit 'SelectedParticipantChanged', nick
      return

    nick = null  if @state.selectedParticipant is nick
    @setState { selectedParticipant: nick }

    @emit 'SelectedParticipantChanged', nick


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


  getActiveParticipant: -> @state.activeParticipant


  getSelectedParticipant: -> @state.selectedParticipant


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

    participant             = @getParticipant nickname
    { isDefaultSubscriber } = helper

    if participant and not isDefaultSubscriber participant
    then callback participant.videoData.stream.hasAudio
    else callback no


getCameraOptionFromState = (state) ->

  if state then { publishVideo: yes } else { videoSource: null }


