class VideoChatController extends KDController

  # @param {SocialChannel} options.channel
  constructor: (options = {}, data) ->

    super options, data

    @openTok = OpenTokController.getInstance()

    { @channel, @view } = options

    @view or= new VideoChatView { delegate: this }

    @session     = null
    @publisher   = null
    @stream      = null
    @subscribers = {}

    @openTok.whenReady().then @bound 'init'


  getView: -> @view
  getChannel: -> @channel


  ###*
   * Gives the initial kick-off for video-chat process.
   *
   * @param {Function=} callback
   * @listens OpenTokController~SessionCreated
  ###
  init: (callback = noop) ->

    @openTok.on 'SessionCreated', @bound 'handleSessionCreated'

    @openTok.connect @channel
    @subscribe()


  ###*
   * Starts publishing video.
   *
   * It ensures that OpenTokController instance
   * is ready to work via its whenReady method.
   * The options argument is just a convinient way to extend
   * publisher options when starting publishing.
   * `OpenTokController#createPublisher` has necessary defaults already.
   *
   * @param {Object=} options - publisher options to be passed.
   * @listens OpenTokController~CameraAccessAllowed
   * @listens OpenTokController~CameraAccessDenied
   * @listens OpenTokController~CameraQuestionAsked
   * @listens OpenTokController~CameraQuestionAnswered
   * @listens OpenTokController~StreamDestroyed
  ####
  startPublishing: (options) -> @openTok.whenReady().then =>

    @openTok
      .on 'CameraAccessAllowed',          @view.bound 'show'
      .on 'CameraAccessDenied',           @view.bound 'hide'
      .on 'CameraAccessQuestionAsked',    @view.bound 'showAccessModal'
      .on 'CameraAccessQuestionAnswered', @view.bound 'hideAccessModal'
      .on 'StreamDestroyed',              @bound 'handleStreamDestroyed'

    @publisher = @openTok.createPublisher @view.getElement(), options

    @session.publish @publisher, (err) =>

      return warn { message: 'Publishing error.' }  if err

      { @stream } = @publisher
      me = KD.nick()

      @fixParticipantVideo subscriber  for _, subscriber of @subscribers
      @switchTo me


  ###*
   * Subscribes to channel video session.
   *
   * It ensures that OpenTokController instance is ready.
   *
   * @listens OpenTokController~NewSubscriber
  ####
  subscribe: -> @openTok.whenReady().then =>

    @openTok.on 'NewSubscriber', @bound 'handleNewSubscriber'

    @openTok.subscribeToVideoUpdates @channel, @view


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
   * This is probably wrong but the way OpenTok sessions
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


assign = (target, source) ->

  target[key] = value for own key, value of source

  return target

