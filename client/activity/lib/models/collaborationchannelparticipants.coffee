_                        = require 'lodash'
ChannelParticipantsModel = require './channelparticipants'

module.exports = class CollaborationChannelParticipantsModel extends ChannelParticipantsModel

  defaultState:
    videoActive           : no
    selectedParticipant   : null
    talkingParticipants   : []
    videoParticipants     : []
    connectedParticipants : []

  constructor: (options = {}, data) ->

    super options, data

    @state = _.assign {}, @defaultState, options.state


  ###*
   * Computes preview participants depending on the video active state.
   *
   *     - Delegate to super class when video is not active.
   *     - Return video-active participants when video is active.
   *
   * @param {Immutable.OrderedMap} participants - all participants
   * @return {Immutable.List} computedPreviewParticipants
  ###
  computePreviewParticipants: (participants) ->

    if @state.videoActive
      filtered = participants.filter (participant) =>
        participant.profile.nickname in @state.videoParticipants

      return filtered.toList()

    super


  ###*
   * Computes hidden participants depending on the video active state.
   *
   *     - Delegate to super class when video is not active.
   *     - Return non-video-active participants when video is active.
   *
   * @param {Immutable.OrderedMap} participants - all participants
   * @return {Immutable.List} computedPreviewParticipants
  ###
  computeHiddenParticipants: (participants) ->

    if @state.videoActive
      filtered = participants.filter (participant) =>
        {nickname} = participant.profile
        return @state.videoParticipants.indexOf(nickname) is -1

      return filtered.toList()

    super


  ###*
   * Defensively adds a video participant. Emits change afterwards if wanted.
   *
   * @param {string} nickname
   * @param {boolean=} emitEvent
  ###
  addVideoParticipant: (nickname, emitEvent = yes) ->

    pushToCollection @state.videoParticipants, nickname, =>
      @emitEvent()  if emitEvent


  ###*
   * Defensively removes a video participant. Emits change afterwards if wanted.
   *
   * @param {string} nickname
   * @param {boolean=} emitEvent
  ###
  removeVideoParticipant: (nickname, emitEvent = yes) ->

    removeFromCollection @state.videoParticipants, nickname, =>
      @emitEvent()  if emitEvent


  ###*
   * Sets given username as selected participant. It's a noop if user is not
   * online. Emits change afterwards.
   *
   * @param {string} nickname
   * @param {boolean} isOnline
  ###
  setVideoSelectedParticipant: (nickname, isOnline) ->

    return  unless isOnline

    @state.selectedParticipant = nickname

    @emitChange()


  ###*
   * Defensively add talking participant.
   *
   * @param {string} nickname
  ###
  addTalkingParticipant: (nickname) ->

    pushToCollection @state.talkingParticipants, nickname, =>
      @emitChange()


  ###*
   * Defensively remove talking participant.
   *
   * @param {string} nickname
  ###
  removeTalkingParticipant: (nickname) ->

    removeFromCollection @state.talkingParticipants, nickname, =>
      @emitChange()


  ###*
   * Defensively add active video participant.
   *
   * @param {string} nickname
  ###
  addVideoActiveParticipant: (nickname) ->

    pushToCollection @state.videoParticipants, nickname, =>
      @emitChange()


  ###*
   * Defensively add active video participant.
   *
   * @param {string} nickname
  ###
  removeVideoActiveParticipant: (nickname) ->

    removeFromCollection @state.videoParticipants, nickname, =>
      @emitChange()


  ###*
   * Defensively add connected video participant.
   *
   * @param {string} nickname
  ###
  addVideoConnectedParticipant: (nickname) ->

    pushToCollection @state.connectedParticipants, nickname, =>
      @emitChange()


  ###*
   * Defensively add connected video participant.
   *
   * @param {string} nickname
  ###
  removeVideoConnectedParticipant: (nickname) ->

    removeFromCollection @state.connectedParticipants, nickname, =>
      @emitChange()


  ###*
   * Difference between this and super method, is that this one emits the state
   * with lists as well. This may be better to be moved to super class.
  ###
  emitChange: -> @emit 'change', @getLists(), @state


  ###*
   * Sets video state to given state.
   *
   *     - if resulting state is `active` it will use second parameter as
   *       initial participant list.
   *
   * @param {boolean} state
   * @param {array.<string>} participants
  ###
  setVideoState: (state, participants) ->

    @state.videoActive = state

    if @state.videoActive
      # add video participant without emitting event.
      participants.map (p) => @addVideoParticipant p, no

    # basically we batched the change event updates.
    @emitChange()


###*
 * Pushes to collection with an existential check first.
 * If item is not there already it will push it and will call the callback. If
 * item is already there, this is basically a noop. It won't call the callback
 * and so on. If this is really weird, we can change the accepted callback into
 * a callback that accepts an `err` object (just like the other ones) to make
 * it more familiar.
 *
 * @param {array} collection
 * @param {(string|number)} item
 * @param {function} callback
###
pushToCollection = (collection, item, callback) ->

  # if item is not in collection
  if collection.indexOf(item) is -1
    collection.push item
    callback?()


###*
 * Removes from collection with an existential check first.
 * If item is there already it remove it and will call the callback. If
 * item is not already there, this is basically a noop. It won't call the callback
 * and so on. If this is really weird, we can change the accepted callback into
 * a callback that accepts an `err` object (just like the other ones) to make
 * it more familiar.
 *
 * @param {array} collection
 * @param {(string|number)} item
 * @param {function} callback
###
removeFromCollection = (collection, item, callback) ->

  # if item is in collection
  unless index = collection.indexOf(item) is -1
    collection.splice index, 1
    callback?()


