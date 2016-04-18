{ Base, signature } = require 'bongo'
URL                 = require 'url'
Constants           = require './constants'
GitHubProvider      = require './githubprovider'
GitLabProvider      = require './gitlabprovider'
_                   = require 'lodash'

module.exports = class GitProvider extends Base

  @trait __dirname, '../../traits/protected'

  { revive } = require '../computeproviders/computeutils'
  { permit } = require '../group/permissionset'

  @share()

  @set

    permissions   :
      'import stack template' : [ 'member' ]

    sharedMethods :
      static      :
        importStackTemplate :
          (signature String, Function)


  @importStackTemplate = permit 'import stack template',
    success: revive {
      shouldReviveClient   : yes
      shouldReviveProvider : no
    }, (client, url, callback) ->

      { hostname, pathname } = URL.parse url
      { user } = client.r
      { GITHUB_HOST, GITLAB_HOST } = Constants

      _callback = (err, result) ->
        return callback err  if err
        result = _.extend { originalUrl : url }, result
        callback null, result

      switch hostname
        when GITHUB_HOST
          GitHubProvider.importStackTemplate user, pathname, _callback
        when GITLAB_HOST
          GitLabProvider.importStackTemplate user, pathname, _callback
