kd           = require 'kd'
remote       = require('app/remote').getInstance()
globals      = require 'globals'
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


fetchConfigureData = (options, callback) ->

  fetchChannels (err, channels) ->
    return callback err  if err

    fetch options, (err, response) ->
      return callback err  if err

      { integration, channelIntegration } = response

      { id, token, createdAt, updatedAt, description,
        integrationId, channelId, isDisabled } = channelIntegration

      description     = description or integration.summary
      webhookUrl      = "#{globals.config.integration.url}/#{integration.name}/#{token}"
      integrationType = 'confiured'
      selectedEvents  = []
      data            = { channels, id, integration, token, createdAt,
                          updatedAt, description, integrationId, webhookUrl, isDisabled }

      if channelIntegration.settings
        data.selectedEvents = try JSON.parse channelIntegration.settings.events catch e then []

      if integration.settings?.events
        events = try JSON.parse integration.settings.events catch e then null
        data.settings = { events }

      if integration.name is 'github'
        fetchGithubRepos (err, repositories) =>
          return callback err  if err
          data.repositories = repositories
          callback null, data
      else
        callback null, data


module.exports = {
  list
  find
  fetch
  create
  update
  fetchChannels
  regenerateToken
  fetchGithubRepos
  fetchConfigureData
  fetchChannelIntegrations
}
