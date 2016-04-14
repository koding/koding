{ Base, signature } = require 'bongo'
URL                 = require 'url'
Constants           = require './constants'
GitHubProvider      = require './githubprovider'

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
        { GITHUB_HOST } = Constants

        if hostname is GITHUB_HOST
          GitHubProvider.importStackTemplate user, pathname, callback  
