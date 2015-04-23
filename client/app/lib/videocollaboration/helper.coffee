$               = require 'jquery'
_               = require 'lodash'
kd              = require 'kd'
remote          = require('app/remote').getInstance()
whoami          = require 'app/util/whoami'
getNick         = require 'app/util/nick'
ProfileTextView = require 'app/commonviews/linkviews/profiletextview'

###*
 * Helper utility to be able to pass a fake publisher to the events. Events
 * mostly don't care about OpenTok specific videoData, so it being `null`
 * shouldn't affect anything, so be careful when you are passing
 * `ParticipantType.Participant` instances around.
 *
 * @return {object} publisher - a fake object imitates `ParticipantType.Publisher`
###
defaultPublisher = ->
  nick      : getNick()
  type      : 'publisher'
  videoData : null

###*
 * It makes a request to the backend and gets session id
 * and creates a session with that session id.
 *
 * TODO: add proper error handling
 *
 * @param {SocialChannel} channel - Session will be generated based on channel.
 * @param {function(session: object)} callback - it will be called on success.
###
generateSession = (channel, callback) ->

  $.ajax
    url      : '/-/video-chat/session'
    method   : 'post'
    dataType : 'JSON'
    data     : { channelId: channel.id }
    success  : callback


###*
 * It makes a request to the backend and gets the token for given session id.
 *
 * TODO: add proper error handling and expireTime support.
 *
 * @param {string} options.sessionId - session id for token to be generated.
 * @param {string=} options.role - role of user in video chat.  (e.g 'publisher', 'moderator')
 * @param {number=} options.expireTime - expiration time for a token. Needs to be lower than 30 days.
 * @param {function(token: string)} callback - callback to be called with token from backend.
 * @see {@link https://tokbox.com/opentok/concepts/token_creation.html}
###
generateToken = (options, callback) ->

  { sessionId, role } = options

  role or= 'publisher'

  $.ajax
    url      : "/-/video-chat/token"
    method   : 'post'
    dataType : 'JSON'
    data     : { role, sessionId }
    success  : (options) -> callback options.token


###*
 * Transforms map with `connectionId`s as keys into a map
 * with nicknames as key.
 *
 * @param {object<string, ParticipantType.Subscriber>} subscribers - keys are connectionIds.
 * @param {ParticipantType.Publisher} publisher
###
toNickKeyedMap = (subscribers, publisher) ->

  map = {}

  # we want get participants to return a publisher no matter what, it may not
  # have a video data (e.g while camera is being asked), but views are
  # expecting a Publisher no matter what, and it's how it should be. Video
  # without a publisher is not permitted atm.

  map[subscriber.nick] = subscriber  for own cId, subscriber of subscribers when subscriber

  # if default publisher is mutated via `or=` the passed original is being
  # mutated and affect other parts of the application. That's why copying into
  # another variable happens here. ~Umut
  _publisher = publisher ? defaultPublisher()
  map[_publisher.nick] = _publisher

  return map


###*
 * Subscribes to given stream, appends the DOM element into given view
 * instance's DOM element.
 *
 * @param {OT.Session} session
 * @param {OT.Stream} stream
 * @param {KDView} view
###
subscribeToStream = (session, stream, view, callbacks) ->

  nick = stream.name
  options =
    height       : '100%'
    width        : '100%'
    insertMode   : 'append'
    style        :
      audioLevelDisplayMode    : 'off'
      buttonDisplayMode        : 'off'
      nameDisplayMode          : 'off'
      videoDisabledDisplayMode : 'on'

  remote.cacheable nick, (err, [account]) ->
    return callbacks.error err  if err
    subscriber = session.subscribe stream, view.getElement(), options, (err) ->
      return callbacks.error err  if err
      fixParticipantBackgroundImage subscriber, account
      subscriber.setStyle 'backgroundImageURI', uri = _getGravatarUri account
      callbacks.success subscriber


###*
 * It creates the `OT.Publisher` instance for sending video/audio.
 *
 * @param {KDView} view - view instance for publisher.
 * @param {object=} options - Options to pass to `OT.initPublisher` method
 * @param {string=} options.insertMode
 * @param {string=} options.name
 * @param {objcet=} options.style
 * @return {OT.Publisher} publisher
 * @see {@link https://tokbox.com/opentok/libraries/client/js/reference/OT.html#initPublisher}
###
createPublisher = (view, options = {}, callback) ->

  options.name        or= getNick()
  options.insertMode  or= 'append'
  options.showControls ?= off

  options.height = 265
  options.width  = 325

  publisher = OT.initPublisher view.getElement(), options, ->
    fixParticipantBackgroundImage publisher, whoami()

  callback null, publisher


###*
 * Fix given participant's background image.
 * TODO: investigate if this method is more suitable for VideoViewModel
 *
 * @param {ParticipantType.Participant} participant
 * @param {JAccount} account
###
fixParticipantBackgroundImage = (participant, account) ->

  poster = participant.element.querySelector '.OT_video-poster'
  poster.style.backgroundImage = "url(#{_getGravatarUri account})"
  kd.utils.defer -> poster.style.opacity = 1

  el = document.createElement 'span'
  el.classList.add 'profile-like-view'
  el.innerHTML = getNicename account

  poster.appendChild el


###*
 * Return nickname if present, or firstname + lastname, from given account.
 *
 * @param {JAccount} account
###
getNicename = (account) ->

  { firstName, lastName, nickname } = account.profile

  if firstName is '' and lastName is ''
  then "@#{nickname}"
  else "#{firstName} #{lastName}"


###*
 * Subscribes to audio changes of given subscriber/publisher. It will call given
 * `callbacks.started` when talking started, and will call `callbacks.stopped`
 * when talking stopped.
 *
 * @param {(OT.Subscriber|OT.Publisher)} participant
 * @param {object<string, function>} callbacks
###
subscribeToAudioChanges = (participant, callbacks) ->

  # this object will be used to keep track of talking activity.
  activity = null

  participant.on 'audioLevelUpdated', (event) ->
    now = Date.now()
    # we detected a sound from participant
    if event.audioLevel > 0.1
      # create initial activity with talking flag is off when there is no
      # talking activity.
      if not activity
        activity = {timestamp: now, talking: off}

      # if it's already talking just updated the timestamp.
      else if activity.talking
        activity.timestamp = now

      # detected that user is talking more than .5 second.
      # call `started` function of given `callbacks`.
      else if now - activity.timestamp > 500
        activity.talking = on
        callbacks.started()

    # we have an activity record, it's not updated for the past 1 secs.
    # call `stopped` function of given `callbacks`
    else if activity and now - activity.timestamp > 1000
      callbacks.stopped()  if activity.talking
      activity = null


###*
 * get user's gravatar, return the default avatar if user doesn't have an avatar.
 *
 * @param {JAccount} account
 * @param {number} size
###
_getGravatarUri = (account, size = 355) ->

  {hash} = account.profile
  {protocol} = global.location
  defaultUri = "https://koding-cdn.s3.amazonaws.com/images/one-pixel-dark-square.png"
  return "#{protocol}//gravatar.com/avatar/#{hash}?size=#{size}&d=#{defaultUri}&r=g"


###*
 * Sets given channel's `videoEnabled` state to given state, then calls the
 * callback.
 *
 * @param {SocialChannel} channel
 * @param {boolean} state
 * @param {function(err: (object|null), result: SocialChannel) callback
 * @api private
###
setVideoState = (channel, state, callback) ->

  { payload } = channel

  options =
    id      : channel.id
    payload : _.assign {}, payload, { videoEnabled : state }

  kd.singletons.socialapi.channel.update options, callback


###*
 * Enable given channel's video.
 *
 * @param {SocialChannel} channel
 * @param {function(err: (object|null), result: SocialChannel) callback
###
enableVideo = (channel, callback) -> setVideoState channel, yes, callback


###*
 * Disable given channel's video.
 *
 * @param {SocialChannel} channel
 * @param {function(err: (object|null), result: SocialChannel) callback
###
disableVideo = (channel, callback) -> setVideoState channel, no, callback


###*
 * Check channel's payload to see if video is enabled.
 *
 * @param {SocialChannel} channel
 * @return {boolean} isActive
###
isVideoActive = (channel) -> channel?.payload?.videoEnabled is 'true'


###*
 * Set videoSessionId to paylod of given channel, then call callback.
 *
 * @param {SocialChannel}
 * @param {string} sessionId
 * @param {function} callback
###
setChannelVideoSession = (channel, sessionId, callback) ->

  { payload } = channel

  options =
    id      : channel.id
    payload : _.assign {}, payload, { videoSessionId : sessionId }

  kd.singletons.socialapi.channel.update options, callback


###*
 * Return given channel's video session id. It can be used for boolean checks
 * as if it's a `hasSessionId` named method.
 *
 * @param {SocialChannel} channel
 * @return {string|undefined} id
###
getChannelSessionId = (channel) -> channel?.payload?.videoSessionId


###*
 * @param {KDView} container
 * @param {string} nickname
 * @param {function(err: object)}
###
showOfflineParticipant = (container, nickname, callback) ->

  container.destroySubViews()
  remote.cacheable nickname, (err, [account]) ->
    return callback err  if err
    container.getElement().style.backgroundImage = "url(#{_getGravatarUri account})"
    container.addSubView new ProfileTextView {}, account
    container.show()


###*
 * Default error signal.
 *
 * @param {object} error
###
_errorSignal = (error) ->

  console.error "signal error #{error.reason}"  if error


module.exports = {
  generateSession
  generateToken
  toNickKeyedMap
  subscribeToStream
  createPublisher
  subscribeToAudioChanges
  enableVideo
  disableVideo
  isVideoActive
  setChannelVideoSession
  showOfflineParticipant
  getChannelSessionId
  _errorSignal
}
