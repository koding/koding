Constants   = require './constants'
helpers     = require './utils/helpers'
async       = require 'async'
request     = require 'request'
URL         = require 'url'
urljoin     = require 'url-join'
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


  importStackTemplateData: (client, options, callback) ->

    { url, repo, privateToken } = options
    { user, oauth, group } = client.r

    unless group.config?.gitlab?.enabled
      return callback new KodingError 'GitLab integration is not enabled for this team.'

    gitlabHost = group.config.gitlab.url
    unless urlData = @parseImportData { url, repo, gitlabHost }
      return callback new KodingError 'Repository information is invalid'

    if privateToken or oauthToken = oauth.token
      @importStackTemplateWithToken {
        privateToken, oauthToken
      }, urlData, callback
    else
      @importStackTemplateWithRawUrl urlData, callback


  parseRepo: (url, gitlabHost) ->

    { gitlab } = KONFIG
    [user, repo, branch] = url.split '/'

    port    = if port = gitlab.port then ":#{port}" else ''
    # FIXME update protocol here ~GG
    baseUrl = gitlabHost ? "#{gitlab.host}#{port}"

    branch ?= 'master'
    url     = urljoin baseUrl, user, repo

    if branch isnt 'master'
      url = urljoin url, 'tree', branch

    return { originalUrl : url, baseUrl, user, repo, branch }


  parseImportData: (options = {}) ->

    { url, repo, gitlabHost } = options

    # if user/repo/branch provided as url we will use
    if repo
      return @parseRepo repo, gitlabHost

    { GITLAB_HOST } = Constants
    { protocol, host, pathname } = URL.parse url

    return  if host not in [
      gitlabHost,
      GITLAB_HOST,
      KONFIG.gitlab.host, "#{KONFIG.gitlab.host}:#{KONFIG.gitlab.port}"
    ]

    [ empty, user, repo, tree, branch, rest... ] = pathname.split '/'
    return  if rest.length > 0

    branch ?= 'master'
    baseUrl = "#{protocol}//#{host}"

    return { originalUrl : url, baseUrl, user, repo, branch }


  importStackTemplateWithToken: (tokens, urlData, callback) ->

    { privateToken, oauthToken }    = tokens
    { baseUrl, user, repo, branch } = urlData
    { TEMPLATE_PATH, README_PATH }  = Constants

    apiOptions = { url: baseUrl }

    if oauthToken
      apiOptions.oauth_token = oauthToken
    else if privateToken
      apiOptions.private_token = privateToken
    else
      return callback new KodingError 'Token not provided'

    gitlab = GitlabAPI apiOptions

    queue = [

      (next) ->

        gitlab.projects.all (projects) ->

          project = projects.filter((item) ->
            item.path_with_namespace is "#{user}/#{repo}")[0]

          if project
          then next null, project.id
          else next new KodingError 'No repository found'

      (projectId, next) ->

        gitlab.projects.repository.listBranches projectId, (branches) ->

          branches = branches.filter (_branch) ->
            _branch.name is branch

          if not branches
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
