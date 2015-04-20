_         = require 'lodash'
immutable = require 'immutable'
ChannelParticipantsModel = require './channelparticipants'

module.exports = class CollaborationChannelParticipantsModel extends ChannelParticipantsModel

  defaultState:
    videoActive: no
    selectedParticipant: null
    talkingParticipants: []
    videoParticipants: []

  constructor: (options = {}, data) ->

    super options, data

    @state = _.assign {}, @defaultState, options.state


  computePreviewParticipants: (participants) ->

    if @state.videoActive
      return participants.filter (participant) =>
        participant.profile.nickname in @state.videoParticipants

    super


  computeHiddenParticipants: (participants) ->

    if @state.videoActive
      return participants.filter (participant) =>
        {nickname} = participant.profile
        return @state.videoParticipants.indexOf(nickname) is -1

    super


  addVideoParticipant: (nickname, emitEvent = yes) ->

    index = @state.videoParticipants.indexOf nickname

    if index is -1
      @state.videoParticipants.push nickname  if index is -1
      @emitChange()  if emitEvent


  removeVideoParticipant: (nickname, emitEvent = yes) ->

    index = @state.videoParticipants.indexOf nickname

    unless index is -1
      @state.videoParticipants.splice index, 1
      @emitChange()  if emitEvent


  setVideoSelectedParticipant: (nickname) ->

    @state.selectedParticipant = nickname

    @emitChange()


  addTalkingParticipant: (nickname) ->

    index = @state.talkingParticipants.indexOf nickname

    if index is -1
      @state.talkingParticipants.push nickname  if index is -1
      @emitChange()


  removeTalkingParticipant: (nickname) ->

    index = @state.talkingParticipants.indexOf nickname

    unless index is -1
      @state.talkingParticipants.splice index, 1
      @emitChange()


  addVideoActiveParticipant: (nickname) ->

    index = @state.videoParticipants.indexOf nickname

    if index is -1
      @state.videoParticipants.push nickname  if index is -1
      @emitChange()


  removeVideoActiveParticipant: (nickname) ->

    index = @state.videoParticipants.indexOf nickname

    unless index is -1
      @state.videoParticipants.splice index, 1
      @emitChange()


  emitChange: -> @emit 'change', @getLists(), @state


  setVideoState: (state, participants) ->

    @state.videoActive = state

    if @state.videoActive
      # add video participant without emitting event.
      participants.map (p) => @addVideoParticipant p, no

      # basically we batched the change event updates.
      @emitChange()


