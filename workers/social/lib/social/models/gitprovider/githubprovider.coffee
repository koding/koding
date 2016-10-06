GithubAPI   = require 'github'
KONFIG      = require 'koding-config-manager'
Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
URL         = require 'url'
_           = require 'lodash'
KodingError = require '../../error'

module.exports = GitHubProvider =

  getConfig: -> [ null, { host: Constants.GITHUB_HOST } ]

  importStackTemplateData: (client, options, callback) ->

    { url } = options
    unless urlData = @parseImportData url
      return callback new KodingError 'Repository information is invalid'

    { user, oauth } = client.r

    if oauth
      @importStackTemplateWithOauth oauth, urlData, callback
    else
      @importStackTemplateWithRawUrl urlData, callback


  parseImportData: (url) ->

    { GITHUB_HOST }    = Constants
    { host, pathname } = URL.parse url

    return  unless host is GITHUB_HOST

    [ empty, user, repo, tree, branch, rest... ] = pathname.split '/'
    return  if rest.length > 0

    branch ?= 'master'
    return { originalUrl : url, user, repo, branch }


  importStackTemplateWithOauth: (oauth, urlData, callback) ->

    { githubapi } = KONFIG
    unless githubapi
      return callback new KodingError 'Github api config is missing'

    { debug, timeout, userAgent } = githubapi
    { user, repo, branch } = urlData
    { token } = oauth

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
        options = { user, repo, path: TEMPLATE_PATH, ref: branch }
        repos.getContent options, (err, data) ->
          return next err  if err
          next null, { commitId: data.sha, content: helpers.decodeContent data }

      (next) ->
        options = { user, repo, path: README_PATH, ref: branch }
        repos.getContent options, (err, data) ->
          return next()  if err
          next null, { commitId: data.sha, content: helpers.decodeContent data }
    ]

    return async.series queue, (err, results) ->
      return callback err  if err
      [ template, readme ] = results
      callback null, _.extend { template, readme }, urlData


  importStackTemplateWithRawUrl: (urlData, callback) ->

    { RAW_GITHUB_HOST, TEMPLATE_PATH, README_PATH } = Constants
    { user, repo, branch } = urlData

    queue = [
      (next) ->
        options =
          host   : RAW_GITHUB_HOST
          path   : "/#{user}/#{repo}/#{branch}/#{TEMPLATE_PATH}"
          method : 'GET'
        helpers.loadRawContent options, (err, template) ->
          next null, { content: template }

      (next) ->
        options =
          host   : RAW_GITHUB_HOST
          path   : "/#{user}/#{repo}/#{branch}/#{README_PATH}"
          method : 'GET'
        helpers.loadRawContent options, (err, readme) ->
          next null, { content: readme }
      ]

    return async.series queue, (err, results) ->
      return callback err  if err
      [ template, readme ] = results
      callback null, _.extend { template, readme }, urlData
