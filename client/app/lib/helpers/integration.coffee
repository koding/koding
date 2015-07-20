remote       = require('app/remote').getInstance()
doXhrRequest = require 'app/util/doXhrRequest'

list = (callback) ->

  doXhrRequest
    type     : 'GET'
    endPoint : "/api/integration/"
  , (err, response) ->

    return callback err  if err

    return callback null, response.data

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

module.exports = {
  list
  fetch
  create
  update
  fetchChannelIntegration
  listChannelIntegrations
  regenerateToken
  fetchAllGithubRepos
}
