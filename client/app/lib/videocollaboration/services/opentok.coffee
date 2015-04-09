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
   *
   * @emits OpenTokService~ClientLoaded
  ###
  initOpenTokClient: ->

    options =
      identifier : 'open-tok'
      url        : OPENTOK_URL

    KodingAppsController.appendHeadElement 'script', options, =>
      @emit 'ClientLoaded'
      @_loaded = yes


  ###*
   * Call given callback if loaded, otherwise register callback to be called
   * when 'ClientLoaded' event is emitted.
   *
   * @param {function} callback
   * @listens OpenTokService~ClientLoaded
  ###
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

    kallback = (sessionId) =>
      { apiKey } = globals.config.tokbox
      session = @sessions[channel.id] = OT.initSession apiKey, sessionId
      session.sessionId = sessionId
      return callback session

    # return cached OT.session if that session exists.
    if session = @sessions[id]
      return callback session

    # initate a OT.Session with channel's sessionId if it's present.
    else if sessionId = helper.getChannelSessionId channel
      kallback sessionId

    # first generate a sessionId, then assign that sessionId to channel, and
    # then initiate a new OT.Session.
    else
      helper.generateSession channel, (result) =>
        { sessionId } = result
        helper.setChannelVideoSession channel, sessionId, (err) =>
          kallback sessionId


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
   * @param {SocialChannel} channel
   * @param {String} type
   * @param {function(err: object)} callback
  ###
  sendSignal: (channel, type, callback) ->

    @fetchChannelSession channel, (session) =>
      session.signal { type }, callback


  sendSessionStartSignal: (channel, callback) ->

    @sendSignal channel, 'start', callback


  sendSessionEndSignal: (channel, callback) ->

    @sendSignal channel, 'end', callback


  ###*
   * It destroys the publisher for given social channel.
   *
   * @param {SocialChannel} channel
   * @param {ParticipantType.Publisher} publisher
   * @param {function(err: object)} callback
  ###
  destroyPublisher: (channel, publisher, callback) ->

    @fetchChannelSession channel, (session) ->
      session.unpublish publisher.videoData
      callback null


