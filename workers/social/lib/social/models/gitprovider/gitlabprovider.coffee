Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
request     = require 'request'
URL         = require 'url'
_           = require 'lodash'
GitlabAPI   = require 'gitlab'
KodingError = require '../../error'
KONFIG      = require 'koding-config-manager'


injectQueryStrings = (templateData) ->

  { template: { content }, user, repo, branch } = templateData

  config = { repo: "#{user}/#{repo}", branch }

  { content } = templateData.template

  Object.keys(config).forEach (key) ->
    value   = config[key]
    content = content
      .replace ///\$\{var\.koding_queryString_#{key}\}///g, value

  templateData.template.content = content

  return templateData


getPrivateToken = (options, callback) ->

  { urlData: { baseUrl }, token, juser } = options

  params    =
    url     : "#{baseUrl}/api/v3/user"
    headers : { Authorization : "Bearer #{token}" }

  request.get params, (err, res, body) ->
    return callback err  if err

    try
      data  = JSON.parse body
      token = data.private_token
    catch e
      return callback new KodingError 'Auth failed'

    unless token
      console.log '[GITLAB] TOKEN NOT FOUND ON DATA:', data
      return callback new KodingError 'Auth failed'

    juser.update {
      $set: {
        'foreignAuth.gitlab.privateToken': token
      }
    }, (err) ->

      console.warn 'Error while updating private token:', err  if err

      # Swallow update error here thus we don't need it ~GG
      callback null, token


module.exports = GitLabProvider =

  getConfig: (client) ->

    { r: { group } } = client
    { team, host, port } = KONFIG.gitlab
    port = if port then ":#{port}" else ''
    url  = "#{host}#{port}"

    if group.config?.gitlab?.enabled
      url = group.config.gitlab.url
    else if group.slug isnt team
      return [
        new KodingError 'GitLab integration is not enabled for this team.'
      ]

    return [ null, { host: url } ]


  importStackTemplateData: (importParams, user, callback) ->

    { url, repo, privateToken } = importParams
    return  unless urlData = @parseImportData url, repo

    if privateToken or privateToken = user.getAt 'foreignAuth.gitlab.privateToken'
      @importStackTemplateWithPrivateToken privateToken, urlData, callback
    else if oauth = user.getAt 'foreignAuth.gitlab'
      @importStackTemplateWithOauth oauth, urlData, user, callback
    else
      @importStackTemplateWithRawUrl urlData, callback

    return yes


  parseRepo: (url) ->

    { gitlab } = KONFIG
    [user, repo, branch] = url.split '/'

    port    = if port = gitlab.port then ":#{port}" else ''
    baseUrl = "http://#{gitlab.host}#{port}" # FIXME update protocol here ~GG
    branch ?= 'master'
    url     = "#{baseUrl}/#{user}/#{repo}"

    if branch isnt 'master'
      url = "#{url}/tree/#{branch}"

    return { originalUrl : url, baseUrl, user, repo, branch }


  parseImportData: (url, repo) ->

    # if user/repo/branch provided as url we will use
    if repo
      return @parseRepo repo

    { GITLAB_HOST } = Constants
    { protocol, host, pathname } = URL.parse url

    return  if host not in [
      GITLAB_HOST,
      KONFIG.gitlab.host, "#{KONFIG.gitlab.host}:#{KONFIG.gitlab.port}"
    ]

    [ empty, user, repo, tree, branch, rest... ] = pathname.split '/'
    return  if rest.length > 0

    branch ?= 'master'
    baseUrl = "#{protocol}//#{host}"

    return { originalUrl : url, baseUrl, user, repo, branch }


  importStackTemplateWithOauth: (oauth, urlData, juser, callback) ->

    { baseUrl, user, repo, branch } = urlData
    { token } = oauth

    getPrivateToken { urlData, token, juser }, (err, privateToken) =>

      return callback err  if err

      @importStackTemplateWithPrivateToken privateToken, urlData, callback


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

        gitlab.projects.repository.listBranches projectId, (branches) ->
          if branches.filter((_branch) -> _branch.name is branch).length is 0
          then next new KodingError 'No such branch exists'
          else next null, projectId

      (projectId, next) ->

        params = { projectId, ref: branch, file_path: TEMPLATE_PATH }
        gitlab.projects.repository.showFile params, (file) ->

          template = if file then {
            content  : helpers.decodeContent file
            commitId : file.commit_id
          } else {}

          next null, projectId, template

      (projectId, template, next) ->

        params = { projectId, ref: branch, file_path: README_PATH }
        gitlab.projects.repository.showFile params, (file) ->

          readme = if file then {
            content  : helpers.decodeContent file
            commitId : file.commit_id
          } else {}

          next null, { template, readme }

    ]

    async.waterfall queue, (err, result) ->
      return callback err  if err
      callback null, injectQueryStrings _.extend result, urlData


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
      [ template, readme ] = results
      callback null, injectQueryStrings _.extend {
        template, readme
      }, urlData
