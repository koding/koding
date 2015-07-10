kd              = require 'kd'
actions         = require '../actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
helper          = require 'activity/flux/helpers/messagesearchhelper'

module.exports = class MessageSearchResultsStore extends KodingFluxStore

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actions.MESSAGE_SEARCH_SUCCESS, @handleSearchSuccess


  handleSearchSuccess: (results, { query, channelId, data }) ->

    query = helper.prepareQueryForStore query
    return results.setIn [ channelId, query ], data
