_                        = require 'lodash'
ChannelParticipantsModel = require './channelparticipants'

module.exports = class CollaborationChannelParticipantsModel extends ChannelParticipantsModel

  defaultState:
    videoActive         : no
    selectedParticipant : null
    talkingParticipants : []
    videoParticipants   : []

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

    index = @state.videoParticipants.indexOf nickname

    if index is -1
      @state.videoParticipants.push nickname
      @emitChange()  if emitEvent


  ###*
   * Defensively removes a video participant. Emits change afterwards if wanted.
   *
   * @param {string} nickname
   * @param {boolean=} emitEvent
  ###
  removeVideoParticipant: (nickname, emitEvent = yes) ->

    index = @state.videoParticipants.indexOf nickname

    unless index is -1
      @state.videoParticipants.splice index, 1
      @emitChange()  if emitEvent


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

    index = @state.talkingParticipants.indexOf nickname

    if index is -1
      @state.talkingParticipants.push nickname
      @emitChange()


  ###*
   * Defensively remove talking participant.
   *
   * @param {string} nickname
  ###
  removeTalkingParticipant: (nickname) ->

    index = @state.talkingParticipants.indexOf nickname

    unless index is -1
      @state.talkingParticipants.splice index, 1
      @emitChange()


  ###*
   * Defensively add active video participant.
   *
   * @param {string} nickname
  ###
  addVideoActiveParticipant: (nickname) ->

    index = @state.videoParticipants.indexOf nickname

    if index is -1
      @state.videoParticipants.push nickname
      @emitChange()


  ###*
   * Defensively add active video participant.
   *
   * @param {string} nickname
  ###
  removeVideoActiveParticipant: (nickname) ->

    index = @state.videoParticipants.indexOf nickname

    unless index is -1
      @state.videoParticipants.splice index, 1
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


