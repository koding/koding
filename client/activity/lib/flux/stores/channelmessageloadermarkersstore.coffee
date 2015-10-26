actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'

module.exports = class ChannelMessageLoaderMarkersStore extends KodingFluxStore

  @getterPath = 'ChannelMessageLoaderMarkersStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.ACTIVATE_LOADER_MARKER, @activateMarker
    @on actions.DEACTIVATE_LOADER_MARKER, @deactivateMarker


  activateMarker: (markers, { channelId, messageId, position, autoload }) ->

    markers = ensureMarkerContainers markers, channelId, messageId

    return markers.setIn [channelId, messageId, position], toImmutable { autoload }


  deactivateMarker: (markers, { channelId, messageId, position }) ->

    markers = ensureMarkerContainers markers, channelId, messageId

    return markers.setIn [channelId, messageId, position], no


ensureMarkerContainers = (markers, channelId, messageId) ->

  unless markers.has channelId
    markers = markers.set channelId, immutable.Map()

  unless markers.hasIn [channelId, messageId]
    markers = markers.setIn [channelId, messageId], defaultMarker()

  return markers


defaultMarker = -> toImmutable { after: no, before: no }


