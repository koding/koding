Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
URL         = require 'url'
_           = require 'lodash'

module.exports = GitHubProvider =

  importStackTemplateByUrl: (url, user, callback) ->

    return  unless urlData = @parseImportUrl url

    @importStackTemplateWithRawUrl urlData, callback
    return yes


  parseImportUrl: (url) ->

    { GITLAB_HOST }        = Constants
    { hostname, pathname } = URL.parse url

    return  unless hostname is GITLAB_HOST

    [ empty, user, repo, tree, branch, rest... ] = pathname.split '/'
    return  if rest.length > 0

    branch ?= 'master'
    return { originalUrl : url, user, repo, branch }


  importStackTemplateWithRawUrl: (urlData, callback) ->

    { GITLAB_HOST, TEMPLATE_PATH, README_PATH } = Constants
    { user, repo, branch } = urlData

    queue = [
      (next) ->
        options =
          host   : GITLAB_HOST
          path   : "/#{user}/#{repo}/raw/#{branch}/#{TEMPLATE_PATH}"
          method : 'GET'
        helpers.loadRawContent options, next
      (next) ->
        options =
          host   : GITLAB_HOST
          path   : "/#{user}/#{repo}/raw/#{branch}/#{README_PATH}"
          method : 'GET'
        helpers.loadRawContent options, (err, readme) ->
          next null, readme
      ]

    return async.series queue, (err, results) ->
      return callback err  if err
      [ rawContent, description ] = results
      callback null, _.extend { rawContent, description }, urlData
