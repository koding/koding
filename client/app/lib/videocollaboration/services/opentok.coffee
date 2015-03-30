kd                   = require 'kd'
$                    = require 'jquery'
helper               = require '../helper'
globals              = require 'globals'
getNick              = require 'app/util/nick'
KodingAppsController = require '../../kodingappscontroller'

OPENTOK_URL = '//static.opentok.com/webrtc/v2.2/js/opentok.min.js'

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
      url        : OPENTOK_URL

    KodingAppsController.appendHeadElement 'script', options, =>
      @emit 'ClientLoaded'
      @_loaded = yes


  whenReady: (callback) ->

    if @_loaded
    then callback()
    else @once 'ClientLoaded', callback


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
  fetchChannelSession: (channel, callback) ->

    { id } = channel

    return callback @sessions[id]  if @sessions[id]

    helper.generateSession channel, (session) =>

      { sessionId } = session
      { apiKey } = globals.config.tokbox

      session = @sessions[channel.id] = OT.initSession apiKey, sessionId

      session.sessionId = sessionId

      callback session


  ###*
   * Connects to a video-chat session.
   * It doesn't start to send video or audio, anything.
   * Simply subscribes to the updates, creates the session.
   * When the session is created it will be emitted.
   *
   * @param {SocialChannel} channel
   * @param {String} role
   * @param {object} callbacks
  ###
  connect: (channel, callbacks) ->

    @fetchChannelSession channel, (session) =>
      helper.generateToken session, (token) =>
        session.connect token, (err) =>
          if err
          then callbacks.error err
          else callbacks.success session


  ###*
   * Sends a signal with type to given subscriber
   * through given session.
   *
   * @param {OT.Session} session
   * @param {String} type
   * @param {Object=} data
  ###
  sendSignal: (session, type, data = {})->

    signalData = { type, data: JSON.stringify data }
    session.signal signalData, helper._errorSignal


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
      accessAllowed      : => @emit 'CameraAccessAllowed'
      accessDenied       : => @emit 'CameraAccessDenied'
      accessDialogOpened : => @emit 'CameraAccessQuestionAsked'
      accessDialogClosed : => @emit 'CameraAccessQuestionAnswered'

    return publisher


