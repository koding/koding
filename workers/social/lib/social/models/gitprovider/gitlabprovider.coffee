Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
request     = require 'request'
URL         = require 'url'
_           = require 'lodash'
GitlabAPI   = require 'gitlab'
KodingError = require '../../error'
getPrivateToken = (options, callback) ->

  { urlData: { baseUrl }, token } = options

  params    =
    url     : "#{baseUrl}/api/v3/user"
    headers : { Authorization : "Bearer #{token}" }

  request.get params, (err, res, body) ->
    return callback err  if err

    try
      data = JSON.parse body
    catch e
      return callback new KodingError 'Auth failed'

    callback null, data.private_token



module.exports = GitLabProvider =

  importStackTemplateData: (importParams, user, callback) ->

    { url, privateToken } = importParams
    return  unless urlData = @parseImportUrl url

    if privateToken
      @importStackTemplateWithPrivateToken privateToken, urlData, callback
    else
      @importStackTemplateWithRawUrl urlData, callback

    return yes


  parseImportUrl: (url) ->

    { GITLAB_HOST } = Constants
    { protocol, host, pathname } = URL.parse url

    [ empty, user, repo, tree, branch, rest... ] = pathname.split '/'
    return  if rest.length > 0

    branch ?= 'master'
    baseUrl = "#{protocol}//#{host}"

    return { originalUrl : url, baseUrl, user, repo, branch }


  importStackTemplateWithPrivateToken: (privateToken, urlData, callback) ->

    { baseUrl, user, repo, branch } = urlData
    { TEMPLATE_PATH, README_PATH }  = Constants

    gitlab  = GitlabAPI {
      url   : baseUrl
      token : privateToken
    }

    queue = [
      (next) ->

        gitlab.projects.all (projects) ->
          project = projects.filter((item) -> item.path_with_namespace is "#{user}/#{repo}")[0]
          if project
          then next null, project.id
          else next new KodingError 'No repository found'

      (projectId, next) ->
        params = { id : projectId, ref : branch, file_path : TEMPLATE_PATH }
        gitlab.repositoryFiles.get params, (err, file) ->
          return next err  if err
          rawContent = helpers.decodeContent file
          next null, projectId, rawContent

      (projectId, rawContent, next) ->
        params = { id : projectId, ref : branch, file_path : README_PATH }
        gitlab.repositoryFiles.get params, (err, file) ->
          description = helpers.decodeContent file  if file
          next null, { rawContent, description }
    ]

    async.waterfall queue, (err, result) ->
      return callback err  if err
      callback null, _.extend result, urlData


  importStackTemplateWithRawUrl: (urlData, callback) ->

    { GITLAB_HOST, TEMPLATE_PATH, README_PATH } = Constants
    { baseUrl, user, repo, branch } = urlData

    queue = [
      (next) ->
        options =
          host   : baseUrl ? GITLAB_HOST
          path   : "/#{user}/#{repo}/raw/#{branch}/#{TEMPLATE_PATH}"
          method : 'GET'

        helpers.loadRawContent options, next

      (next) ->
        options =
          host   : baseUrl ? GITLAB_HOST
          path   : "/#{user}/#{repo}/raw/#{branch}/#{README_PATH}"
          method : 'GET'

        helpers.loadRawContent options, (err, readme) ->
          next null, readme
      ]

    return async.series queue, (err, results) ->
      return callback err  if err
      [ rawContent, description ] = results
      callback null, _.extend { rawContent, description }, urlData
