kd             = require 'kd'
_              = require 'lodash'
OpenTokService = require './services/opentok'
kd              = require 'kd'
_               = require 'lodash'
getNick         = require 'app/util/nick'

OpenTokService  = require './services/opentok'
ParticipantType = require './types/participant'

module.exports = class VideoCollaborationModel extends kd.Object

  defaultState:
    video              : on
    audio              : on
    publishing         : off
    connectedToSession : no
    maxConnectionCount : 999
    activeParticipant  : null

  # @param {SocialChannel} options.channel
  # @param {BaseChatVideoView} options.view
  constructor: (options = {}, data) ->

    super options, data

    @_service = OpenTokService.getInstance()
    @state = _.assign {}, options.state, @defaultState

    { @channel, @view } = options

    @session     = null
    @publisher   = null
    @stream      = null
    @subscribers = {}

    @_service.whenReady @bound 'init'


  ###*
   * Returns the view.
   *
   * @return {KDView} view
  ###
  getView: -> @view
  getChannel: -> @channel


  ###*
   * Gives the initial kick-off for video-chat process.
   *
   * @param {Function=} callback
   * @listens OpenTokService~SessionCreated
  ###
  init: (callback = kd.noop) ->

    @_service.on 'SessionCreated', @bound 'handleSessionCreated'

    @_service.connect @channel
    @subscribe()


  ###*
   * Starts publishing video.
   *
   * It ensures that OpenTokService instance
   * is ready to work via its whenReady method.
   * The options argument is just a convinient way to extend
   * publisher options when starting publishing.
   * `OpenTokService#createPublisher` has necessary defaults already.
   *
   * @param {Object=} options - publisher options to be passed.
   * @listens OpenTokService~CameraAccessAllowed
   * @listens OpenTokService~CameraAccessDenied
   * @listens OpenTokService~CameraQuestionAsked
   * @listens OpenTokService~CameraQuestionAnswered
   * @listens OpenTokService~StreamDestroyed
  ###
  startPublishing: (options) -> @_service.whenReady =>

    @_service
      .on 'CameraAccessAllowed',          @view.bound 'show'
      .on 'CameraAccessDenied',           @view.bound 'hide'
      .on 'CameraAccessQuestionAsked',    @view.bound 'showAccessModal'
      .on 'CameraAccessQuestionAnswered', @view.bound 'hideAccessModal'
      .on 'StreamDestroyed',              @bound 'handleStreamDestroyed'

    @publisher = @_service.createPublisher @view.getElement(), options

    @session.publish @publisher, (err) =>

      return warn { message: 'Publishing error.' }  if err

      { @stream } = @publisher
      me = KD.nick()

      @fixParticipantVideo subscriber  for _, subscriber of @subscribers
      @switchTo me


  ###*
   * Subscribes to channel video session.
   *
   * It ensures that OpenTokService instance is ready.
   *
   * @listens OpenTokService~NewSubscriber
  ###
  subscribe: -> @_service.whenReady =>

    @_service.on 'NewSubscriber', @bound 'handleNewSubscriber'

    @_service.subscribeToVideoUpdates @channel, @view


  ###*
   * Session creation handler.
   *
   * @param {OT.Session} session
  ###
  handleSessionCreated: (session) ->

    @session = session


  ###*
   * New subscriber handler.
   * It sets a value with the nickname of
   * user in the `subscribers` object.
   *
   * @param {OT.Subscriber} subscriber
  ###
  handleNewSubscriber: (subscriber) ->

    { nick, video } = subscriber


  ###*
   * Stream destroy handler. Sets back some defaults.
   * TODO: Destroy maybe?
  ###
  handleStreamDestroyed: (event) ->

    @publisher = null


  ###*
   * Returns all the participants including the publisher(Logged in user).
   *
   * @return {Object} participants
  ###
  getParticipants: ->

    participants = _.assign {}, @subscribers
    participants[KD.nick()] = { video: @publisher }

    return participants


  ###*
   * Switch to given users video feed.
   *
   * @param {String} nick
  ###
  switchTo: (nick) ->

    return  unless participant = @getParticipants()[nick]

    @hideAll()
    @showParticipant participant


  ###*
   * Hides all video feeds.
  ###
  hideAll: ->

    @hideParticipant participant  for own _, participant of @getParticipants()


  ###*
   * Hides given participant's video feed.
   *
   * @param {OT.Subscriber|OT.Publisher} participant
  ###
  hideParticipant: (participant) ->

    { video } = participant
    video.element.style.display = 'none'


  ###*
   *
  ###




  ###*
   * Merges instance state with given state.
   *
   * @param {object} _state
   * @return {object} state
  ###
  setState: (state) -> @state = _.assign {}, @state, state


