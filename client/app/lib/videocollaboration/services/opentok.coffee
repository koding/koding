kd                   = require 'kd'
$                    = require 'jquery'
helper               = require '../helper'
KodingAppsController = require '../../kodingappscontroller'

module.exports = class OpenTokService extends kd.Object

  ###*
   * This class needs to be used as a singleton. This can either be temp,
   * or a real use case. It can be added onto `KD.singletons` object or
   * this method does exactly that.
   *
   * @return {OpenTokService} singleton instance of the class.
  ###
  @getInstance: do ->

    instance = null
    return -> instance or= new OpenTokService


  constructor: (options = {}, data) ->

    super options, data

    ### @type {Object} ###
    @sessions = {}

    ### @type {Object} ###
    @publishers = {}

    ###* @type {Object} ###
    @subscribers = {}

    ###* @type {Boolean} ###
    @_loaded = no

    @initOpenTokClient()


  ###*
   * Initializes the client library of OpenTok.
   * TODO: It may be wise to include this in our bundle?
   *
   * @emits OpenTokService#ClientLoaded
  ###
  initOpenTokClient: ->

    options =
      identifier : 'open-tok'
      url        : '//static.opentok.com/webrtc/v2.2/js/opentok.min.js'

    KodingAppsController.appendHeadElement 'script', options, =>
      @emit 'ClientLoaded'
      @_loaded = yes


  whenReady: (callback) ->

    if @_loaded
    then callback()
    else @once 'ClientLoaded', callback


  ###*
   * It makes a request to the backend and gets session id
   * and creates a session with that session id.
   *
   * @param {SocialChannel} channel - Session will be generated based on channel.
   * @param {Function=} callback - it will be called on success.
   * @private
  ###
  generateChannelSession = (channel, callback) ->

    $.ajax
      url      : '/-/video-chat/session'
      method   : 'post'
      dataType : 'JSON'
      data     : { channelId: channel.id }
      success  : callback


  ###*
   * It makes a request to the backend and gets the token for given session id.
   *
   * @param {string} options.sessionId - session id for token to be generated.
   * @param {string=} options.role - role of user in video chat.  (e.g 'publisher', 'moderator')
   * @param {number=} options.expireTime - expiration time for a token. Needs to be lower than 30 days.
   * @param {Function=} callback - callback to be called with token from backend.
   * @see {@link https://tokbox.com/opentok/concepts/token_creation.html}
  ###
  getToken = (options, callback) ->

    { sessionId, role } = options

    role or= 'publisher'

    $.ajax
      url      : "/-/video-chat/token"
      method   : 'post'
      dataType : 'JSON'
      data     : { role, sessionId }
      success  : (options) -> callback options.token


  ###*
   * It gets the session for channel and calls the callback with it.
   *
   * It can call the callback with following:
   *
   *  - Generate the session if it doesn't exist and call with it.
   *  - Call the callback with cached session isntance for that channel.
   *
   * @param {SocialChannel} channel - Pair channel of session.
   * @param {Function=} callback - it will be called with the session object.
  ###
  getChannelSession: (channel, callback) ->

    # TODO: move this to config.
    API_KEY = '45082272'

    { id } = channel

    return callback @sessions[id]  if @sessions[id]

    generateChannelSession channel, (session) =>

      { sessionId } = session

      session = @sessions[channel.id] = OT.initSession API_KEY, sessionId

      session.sessionId = sessionId

      callback session


  ###*
   * This method is necessary to be called before everything to be able
   * to get updates from tokbox. It registers the given view's dom element
   * as a container for the video chat session.
   *
   * When publishing from a client, we are adding `KD.nick()` as `name`
   * in `publisherOptions`, when we want to cache the subscribers for easy
   * access later, we are getting that published name from stream's name property
   * when we are listening session's `streamCreated` event. And we are using it
   * as a key to write instance's `subscribers` object when the subscriber is created.
   * So that we can be able to switch the main video to subscriber videos, by
   * just using user's `nickname`.
   *
   * @param {SocialChannel} channel
   * @param {KDView} view - container view for video chat.
   * @param {Object} options - options to be passed to subscribe event
   * @listens OT.session~streamCreated
  ###
  subscribeToVideoUpdates: (channel, view, options = {}) ->

    @getChannelSession channel, (session) =>

      { sessionId } = session

      session.on 'streamCreated', (event) =>

        options.height     or= "100%"
        options.width      or= "100%"
        options.insertMode or= 'append'

        { stream } = event
        nick       = stream.name
        element    = view.getElement()
        subscriber = session.subscribe stream, element, options

        @emit 'NewSubscriber', { nick, video: subscriber }


  ###*
   * Connects to a video-chat session.
   * It doesn't start to send video or audio, anything.
   * Simply subscribes to the updates, creates the session.
   * When the session is created it will be emitted.
   *
   * @param {SocialChannel} channel
   * @param {String} role
  ###
  connect: (channel, role) ->

    @getChannelSession channel, (session) =>
      { sessionId } = session
      getToken { sessionId, role }, (token) =>
        session.connect token, (err) =>
          return warn { err }  if err
          @emit 'SessionCreated', session

          session.on 'connectionCreated', \
            @lazyBound 'emit', 'ConnectionCreated'


  ###*
   * Sends a signal with type to given subscriber
   * through given session.
   *
   * @param {OT.Session} session
   * @param {String} type
   * @param {OT.Subscriber} to
   * @param {Object=} data
  ###
  sendSignal: (session, type, to, data = {})->

    data.to = to

    # TODO: proper signal error handling maybe?
    session.signal data, _errorSignal


  ###*
   * Default error signal.
  ###
  _errorSignal = (error) ->

    log "signal error #{error.reason}"  if error


  ###*
   * It creates the `OT.Publisher` instance for sending video/audio.
   * It listens to publisher events and emits KDEvents to the passed view.
   *
   * @param {KDView} view - view instance for publisher.
   * @param {Object=} publisherOptions - Options to pass to `OT.initPublisher` method
   * @param {string=} publisherOptions.insertMode
   * @param {string=} publisherOptions.name
   * @param {Object=} publisherOptions.style
   * @return {OT.Publisher} publisher
   * @see {@link https://tokbox.com/opentok/libraries/client/js/reference/OT.html#initPublisher}
  ###
  createPublisher: (element, publisherOptions = {}) ->

    publisherOptions.name       or= KD.nick()
    publisherOptions.style      or= { nameDisplayMode: on }
    publisherOptions.insertMode or= 'append'

    publisherOptions.height = 265
    publisherOptions.width  = 325

    publisher = OT.initPublisher element, publisherOptions

    publisher.on
      accessAllowed      : (event) => @emit 'CameraAccessAllowed'
      accessDenied       : (event) => @emit 'CameraAccessDenied'
      accessDialogOpened : (event) => @emit 'CameraAccessQuestionAsked'
      accessDialogClosed : (event) => @emit 'CameraAccessQuestionAnswered'

    return publisher


