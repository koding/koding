kd           = require 'kd'
remote       = require('app/remote').getInstance()
globals      = require 'globals'
doXhrRequest = require 'app/util/doXhrRequest'
whoami       = require 'app/util/whoami'


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


fetch = (name, callback) ->

  doXhrRequest
    type     : 'GET'
    endPoint : "/api/integration/#{name}"
  , (err, response) ->

    return callback err  if err

    return callback null, response.data


fetchChannelIntegration = (options, callback) ->
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


remove = (id, callback) ->

  doXhrRequest
    endPoint : "/api/integration/channelintegration/#{id}"
    type     : 'DELETE'
  , callback


listChannelIntegrations = (callback) ->

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


fetchAllGithubRepos = (callback) ->

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

    fetchChannelIntegration options, (err, response) ->
      return callback err  if err

      { integration, channelIntegration } = response

      { id, token, createdAt, updatedAt, description,
        integrationId, channelId, isDisabled, settings } = channelIntegration

      description     = description or integration.summary
      webhookUrl      = "#{globals.config.webhookMiddleware.url}/#{integration.name}/#{token}"
      integrationType = 'configured'
      selectedEvents  = []
      name            = settings?.customName or integration.title
      selectedChannel = channelId
      data            = { channels, id, integration, token, createdAt, name, selectedChannel,
                          updatedAt, description, integrationId, webhookUrl, isDisabled }


      if channelIntegration.settings
        data.selectedEvents = try JSON.parse channelIntegration.settings.events catch e then []

      if integration.settings?.events
        events = try JSON.parse integration.settings.events catch e then null
        data.settings = { events }

      data.authorizable = integration.settings?.authorizable is 'true'

      return callback null, data  unless data.authorizable

      whoami().isAuthorized integration.name, (err, isAuthorized) ->

        return callback err  if err

        return callback null, data  unless isAuthorized

        data.isAuthorized = isAuthorized

        if integration.name is 'github'
          fetchAllGithubRepos (err, repositories) =>
            return callback err  if err
            data.repositories = repositories
            data.selectedRepository = channelIntegration.settings?.repository
            callback null, data
        else
          callback null, data


module.exports = {
  list
  find
  fetch
  create
  update
  remove
  fetchChannels
  fetchConfigureData
  fetchChannelIntegration
  listChannelIntegrations
  regenerateToken
  fetchAllGithubRepos
}
