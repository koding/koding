{ argv }  = require 'optimist'
GithubAPI = require 'github'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
Constants = require './constants'
helpers   = require './helpers'
async     = require 'async'

module.exports = GitHubProvider =

  importStackTemplate: (user, path, callback) ->

    [ empty, username, repo ] = path.split '/'
    oauth = user.getAt 'foreignAuth.github'

    if oauth
      GitHubProvider.importStackTemplateWithOauth oauth, username, repo, path, callback
    else
      GitHubProvider.importStackTemplateWithRawUrl username, repo, path, callback


  importStackTemplateWithOauth: (oauth, user, repo, path, callback) ->

    { token } = oauth
    { debug, timeout, userAgent } = KONFIG.githubapi

    gh = new GithubAPI {
      version : '3.0.0'
      headers : { 'user-agent': userAgent }
      debug, timeout
    }

    gh.authenticate { type: 'oauth', token }

    { repos } = gh
    { TEMPLATE_PATH, README_PATH } = Constants
    queue = [
      (next) ->
        repos.getContent { user, repo, path: TEMPLATE_PATH }, (err, data) ->
          return next err  if err
          next null, helpers.decodeContent data
      (next) ->
        repos.getContent { user, repo, path: README_PATH }, (err, data) ->
          return next()  if err
          next null, helpers.decodeContent data
    ]

    return async.series queue, (err, results) ->
      [ template, readme ] = results
      callback err, { template, readme }


  importStackTemplateWithRawUrl: (user, repo, path, callback) ->

    { RAW_GITHUB_HOST, TEMPLATE_PATH, README_PATH } = Constants

    queue = [
      (next) ->
        options =
          host   : RAW_GITHUB_HOST
          path   : "/#{user}/#{repo}/master/#{TEMPLATE_PATH}"
          method : 'GET'
        helpers.loadRawContent options, (template) ->
            next null, template
        (next) ->
          options =
            host   : RAW_GITHUB_HOST
            path   : "/#{user}/#{repo}/master/#{README_PATH}"
            method : 'GET'
          helpers.loadRawContent options, (readme) ->
            next null, readme
      ]

    return async.series queue, (err, results) ->
      [ template, readme ] = results
      callback null, { template, readme }
