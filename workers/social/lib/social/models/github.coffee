{ Base, signature } = require 'bongo'
KodingError         = require '../error'

{ argv }  = require 'optimist'
GithubAPI = require 'github'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Github extends Base

  OAUTH_PROVIDER = 'github'

  @trait __dirname, '../traits/protected'

  { revive } = require './computeproviders/computeutils'
  { permit } = require './group/permissionset'

  @share()

  @set
    permissions           :
      'list repos'        : ['member','moderator']
      'fetch content'     : ['member','moderator']

    sharedMethods         :
      static              :
        listRepos         :
          (signature Object, Function)
        fetchContent      :
          (signature Object, Function)


  @listRepos = permit 'list repos', success: revive

    shouldReviveProvider : no
    shouldHaveOauth      : OAUTH_PROVIDER

  , (client, options, callback) ->

    { oauth: {foreignId}, user: {username} } = client.r

    gh = new GithubAPI
      version        : '3.0.0'
      debug          : true
      timeout        : 5000
      headers        :
        'user-agent' : 'Koding-Bridge'

    gh.authenticate
      type           : 'oauth'
      token          : foreignId

    gh.repos.getAll {}, (err, res) ->
      callback err, res


  @fetchContent = permit 'fetch content', success: revive

    shouldReviveProvider : no
    shouldHaveOauth      : OAUTH_PROVIDER

  , (client, options, callback) ->

    callback new KodingError 'Not Implemented.'
