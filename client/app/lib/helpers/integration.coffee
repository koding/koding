kd           = require 'kd'
remote       = require('app/remote').getInstance()
doXhrRequest = require 'app/util/doXhrRequest'


list = (callback) ->

  doXhrRequest
    type     : 'GET'
    endPoint : "/api/integration/"
  , (err, response) ->

    return callback err  if err

    return callback null, response.data


find = (query, callback) ->

  list (err, items) ->

    return callback err  if err

    query = decodeURIComponent query

    for item in items when item.name is query or item.title is query
      integration = item

    return callback { message: 'Not found' }  unless integration

    fetchChannels (err, channels) =>
      return callback err  if err

      integration.channels = channels

      callback null, integration


fetchChannels = (callback) ->

  kd.singletons.socialapi.account.fetchChannels (err, channels) ->

    return callback err  if err

    decoratedChannels = []

    for channel in channels
      { id, typeConstant, name, purpose, participantsPreview } = channel

      # TODO after refactoring the private channels, we also need to add them here
      if typeConstant is 'topic' or typeConstant is 'group'
        decoratedChannels.push { name:"##{name}", id }

    callback null, decoratedChannels


fetch = (options, callback) ->
  { id } = options

  doXhrRequest
    type     : 'GET'
    endPoint : "/api/integration/channelintegration/#{id}"
  , (err, response) ->

    return callback err  if err

    return callback null, response.data


create = (options, callback) ->

  doXhrRequest
    endPoint : "/api/integration/channelintegration"
    type     : 'POST'
    data     : options
  , (err, response) ->

    return callback err  if err

    return callback null, response.data


update = (options, callback) ->

  { id } = options
  doXhrRequest
    endPoint : "/api/integration/channelintegration/#{id}"
    type     : 'POST'
    data     : options
  , callback


fetchChannelIntegrations = (callback) ->

  doXhrRequest
    endPoint : "/api/integration/channelintegration"
    type     : 'GET'
  , (err, response) ->
    return callback err  if err

    return callback null, response.data


regenerateToken = (options, callback) ->

  doXhrRequest
    endPoint : "/api/integration/channelintegration/token"
    type     : 'POST'
    data     : options
  , (err, response) ->
    return callback err  if err

    return callback null, response.data


fetchGithubRepos = (callback) ->

  page = 1
  result = []

  fetch = ->
    _options =
      method     : "repos.getAll"
      pluck      : ['full_name']
      options    :
        per_page : 100
        page     : page

    remote.api.Github.api _options, (err, response) ->

      return callback err  if err

      result = result.concat response

      return callback null, result if response.length < 100

      page++

      fetch()

  fetch()

module.exports = {
  list
  find
  fetch
  create
  update
  fetchChannels
  regenerateToken
  fetchGithubRepos
  fetchChannelIntegrations
}
