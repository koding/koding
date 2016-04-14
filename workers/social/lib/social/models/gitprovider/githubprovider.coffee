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
    repos.getContent { user, repo, path: TEMPLATE_PATH }, (err, templateData) ->
      return callback err  if err

      template = helpers.decodeContent templateData

      repos.getContent { user, repo, path: README_PATH }, (err, readmeData) ->
        readme = helpers.decodeContent readmeData  unless err
        callback null, { template, readme }


  importStackTemplateWithRawUrl: (user, repo, path, callback) ->

    { RAW_GITHUB_HOST, TEMPLATE_PATH, README_PATH } = Constants

    queue = [
      (next) ->
        templateOptions =
          host   : RAW_GITHUB_HOST
          path   : "/#{user}/#{repo}/master/#{TEMPLATE_PATH}"
          method : 'GET'
        helpers.loadRawContent templateOptions, (template) ->
            next null, template
        (next) ->
          readmeOptions =
            host   : RAW_GITHUB_HOST
            path   : "/#{user}/#{repo}/master/#{README_PATH}"
            method : 'GET'
          helpers.loadRawContent readmeOptions, (readme) ->
            next null, readme
      ]

    return async.series queue, (err, results) ->
      [ template, readme ] = results
      callback null, { template, readme }
