{ argv }    = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
KodingError = require '../../error'

module.exports = GitHubProvider =

  importStackTemplate: (user, path, callback) ->

    [ empty, username, repo, tree, branch, rest... ] = path.split '/'
    return callback(new KodingError 'Invalid url')  if rest.length > 0

    GitHubProvider.importStackTemplateWithRawUrl username, repo, branch, callback


  importStackTemplateWithRawUrl: (user, repo, branch, callback) ->

    { GITLAB_HOST, TEMPLATE_PATH, README_PATH } = Constants
    branch ?= 'master'

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
      callback null, { rawContent, description, user, repo, branch }
