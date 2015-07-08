remote       = require('app/remote').getInstance()
doXhrRequest = require 'app/util/doXhrRequest'

list = (callback) ->

  doXhrRequest
    type     : 'GET'
    endPoint : "/api/integration/list"
  , (err, response) ->

    return callback err  if err

    return callback null, response.data

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
    endPoint : "/api/integration/channelintegration/create"
    type     : 'POST'
    data     : options
  , (err, response) ->

    return callback err  if err

    return callback null, response.data


update = (options, callback) ->

  { id } = options
  doXhrRequest
    endPoint : "/api/integration/channelintegration/#{id}/update"
    type     : 'POST'
    data     : options
  , callback


fetchChannelIntegrations = (callback) ->

  doXhrRequest
    endPoint : "/api/integration/channelintegrations"
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
  fetch
  create
  update
  fetchChannelIntegrations
  regenerateToken
  fetchGithubRepos
}
