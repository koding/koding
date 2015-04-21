immutable     = require 'immutable'
kd            = require 'kd'
fetchAccounts = require 'app/util/fetchAccounts'
sinkrow       = require 'sinkrow'

###*
 * A model class to handle participant works of given channel. Hopefully this
 * will evolve and be a part of `ChannelModel`.
 *
 * This class is responsible of:
 *
 *     - transforming participant previews initially
 *     - listening realtime events and transforming them into JAccount instances
 *     - emitting an event when a change happens on the participants list so
 *       that any other class can listen to it.
 *
 * It uses ImmutableJS for dealing with data structures.
 *
 * @class
###
module.exports = class ChannelParticipantsModel extends kd.Object

  constructor: (options = {}) ->

    super options

    @setChannel options.channel

    @participants = immutable.OrderedMap()

    fetchAccounts @channel.participantsPreview, (err, accounts) =>
      return console.error err  if err
      @setParticipant account  for account in accounts
      @emitChange()

    @fetchFromBackend()


  ###*
   * Sets given channel, unbinds events if there is already a channel and binds
   * the events to given channel.
   *
   * @param {SocialChannel} channel
  ###
  setChannel: (channel) ->

    # unbind listeners first there is a channel.
    if @channel
      @channel.off 'AddedToChannel', @bound 'add'
      @channel.off 'RemovedFromChannel', @bound 'remove'

    channel.on 'AddedToChannel', @bound 'add'
    channel.on 'RemovedFromChannel', @bound 'remove'

    @channel = channel


  ###*
   * Fetch channel's all participants from backend. Transforms it them into jAccounts.
  ###
  fetchFromBackend: (emitEvent = yes) ->

    fetchParticipants @channel.id, (err, accounts) =>
      return console.log err  if err
      @setParticipant account  for account in accounts
      @emitChange()  if emitEvent


  ###*
   * Saves given account into instance's participants map. It doesn't change
   * the participant if there is a participant with that id, it's a noop.
   *
   * @param {JAccount} account
   * @return {Immutable.OrderedMap}
  ###
  setParticipant: (account) ->

    return @participants  if @participants.get account._id

    @participants = @participants.set account._id, immutable.fromJS account


  ###*
   * Takes an origin object, fetchs the jAccount instance related with that
   * origin, then caches the participant on participants object. It will emit
   * change event unless otherwise noted via `emitEvent` parameter.
   *
   * @param {object} origin - an object with id and a constructor name for bongo.
   * @param {boolean=} emitEvent
  ###
  add: (origin, emitEvent = yes) ->

    fetchAccounts [origin], (err, accounts) =>
      return console.error err  if err
      [account] = accounts
      @setParticipant account
      @emitChange()  if emitEvent


  ###*
   * Removes the cached object from instance's participants object. If there is
   * not a participant with that id, it's a noop.
   *
   * @param {object} origin
   * @param {boolean=} emitEvent
  ###
  remove: (origin, emitEvent = yes) ->

    # sanitize the origin first.
    origin.id or= origin._id

    return  unless @participants.get origin.id

    @participants = @participants.remove origin.id
    @emitChange()  if emitEvent


  ###*
   * Provides basic computation to populate preview participants. This is just
   * a bare-bones implementation for regular PrivateMessages. Subclasses should
   * implement this method to modify how preview list should be populated.
   *
   * @param {Immutable.OrderedMap} participants - all participants
   * @return {Immutable.List} computedPreviewParticipants
  ###
  computePreviewParticipants: (participants) ->

    return participants.toSeq().take(5).toList()


  ###*
   * Provides basic computation to populate preview participants. This is just
   * a bare-bones implementation for regular PrivateMessages. Subclasses should
   * implement this method to modify how preview list should be populated.
   *
   * @param {Immutable.OrderedMap} participants - all participants
   * @return {Immutable.List} computedHiddenParticipants
  ###
  computeHiddenParticipants: (participants) ->

    return participants.toSeq().skip(5).toList()


  ###*
   * Provides basic computation to populate preview participants. This is just
   * a bare-bones implementation for regular PrivateMessages. Subclasses should
   * implement this method to modify how preview list should be populated.
   *
   * @param {Immutable.OrderedMap} participants - all participants
   * @return {Immutable.List} computedAllParticipants
  ###
  computeAllParticipants: (participants) ->

    return participants.toList()


  ###*
   * First computes all participants via:
   * - `computeAllParticipants`
   *
   * Then passes that into:
   * - `computePreviewParticipants`
   * - `computeHiddenParticipants`
   *
   * Composes a regular JS object with 3 of those lists and returns that.
   *
   * @return {object}
  ###
  getLists: ->

    all = @computeAllParticipants @participants

    lists =
      preview : @computePreviewParticipants all
      hidden  : @computeHiddenParticipants all
      all     : all


  ###*
   * Emit change event with computed lists that is computed with current
   * participants.
   *
   * @emits ChatParticipantHeads~change
  ###
  emitChange: -> @emit 'change', @getLists()


  ###*
  * Convinience method for other classes to easily add a handler to be called
  * whenever participants list is changed.
  *
  * @param {function} callback
  ###
  addChangeListener: (callback) -> @on 'change', callback


###*
 * Wrapper function around SocialApiController::channel.listParticipants.
###
fetchParticipants = (id, callback) ->

  {socialapi} = kd.singletons

  socialapi.channel.listParticipants {channelId: id}, (err, participants) ->
    return callback err  if err
    origins = participants.map ({accountOldId}) ->
      return { id: accountOldId, constructorName: 'JAccount' }
    fetchAccounts origins, callback


