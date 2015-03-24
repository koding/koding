kd             = require 'kd'
_              = require 'lodash'
OpenTokService = require './services/opentok'

module.exports = class VideoCollaborationModel extends kd.Object

  # @param {SocialChannel} options.channel
  constructor: (options = {}, data) ->

    super options, data

    @_service = OpenTokService.getInstance()

    { @channel, @view } = options

    @session     = null
    @publisher   = null
    @stream      = null
    @subscribers = {}

    @_service.whenReady().then @bound 'init'


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
  ####
  startPublishing: (options) -> @_service.whenReady().then =>

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
  ####
  subscribe: -> @_service.whenReady().then =>

    @_service.on 'NewSubscriber', @bound 'handleNewSubscriber'

    @_service.subscribeToVideoUpdates @channel, @view


  ###*
   * Session creation handler.
   *
   * @param {OT.Session} session
  ####
  handleSessionCreated: (session) ->

    @session = session


  ###*
   * New subscriber handler.
   * It sets a value with the nickname of
   * user in the `subscribers` object.
   *
   * @param {OT.Subscriber} subscriber
  ####
  handleNewSubscriber: (subscriber) ->

    { nick, video } = subscriber

    @subscribers[nick] = subscriber


  ###*
   * Stream destroy handler. Sets back some defaults.
   * TODO: Destroy maybe?
   *
   * @param {OT.StreamDestroyedEvent} event
  ####
  handleStreamDestroyed: (event) ->

    @publisher = null


  ###*
   * Returns all the participants including the publisher(Logged in user).
   *
   * @return {Object} participants
  ####
  getParticipants: ->

    participants = assign {}, @subscribers
    participants[KD.nick()] = { video: @publisher }

    return participants


  ###*
   * Switch to given users video feed.
   *
   * @param {String} nick
  ####
  switchTo: (nick) ->

    participants = @getParticipants()
    participant  = participants[nick]

    return  unless participant

    @hideAll()
    @showParticipant participant


  ###*
   * Hides all video feeds.
  ####
  hideAll: ->

    participants = @getParticipants()

    @hideParticipant participant  for own _, participant of participants


  ###*
   * Hides given participant's video feed.
   *
   * @param {OT.Subscriber|OT.Publisher} participant
  ####
  hideParticipant: (participant) ->

    { video } = participant

    video.element.style.display = 'none'


  ###*
   * Shows given participant's video feed.
   *
   * @param {OT.Subscriber|OT.Publisher} participant
  ####
  showParticipant: (participant) ->

    { video } = participant

    { element } = video

    element.style.display = 'block'
    @fixParticipantVideo participant


  ###*
   * This is a convinient method.
   * This is probably wrong but the way _service sessions
   * are working makes all subscriber videos invisible.
   * This method's pure existence is to support it.
   * p.s.: 173 is weird.
   *
   * @param {OT.Subscriber|OT.Publisher} participant
  ####
  fixParticipantVideo: (participant) ->

    { video } = participant

    KD.utils.wait 173, ->
      vElement = video.videoElement()
      vElement.style.left   = '-14px'
      vElement.style.height = '265px'
      vElement.style.width  = '355px'

