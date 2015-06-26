{ Base, signature } = require 'bongo'
KodingError         = require '../error'

{ argv }  = require 'optimist'
GithubAPI = require 'github'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Github extends Base

  OAUTH_PROVIDER = 'github'
  USER_AGENT     = 'Koding-Bridge'

  @trait __dirname, '../traits/protected'

  { revive } = require './computeproviders/computeutils'
  { permit } = require './group/permissionset'

  @share()

  @set
    permissions           :

    sharedMethods         :
      static              :

  initGithubFor = (client) ->

    { oauth: {token} } = client.r

    gh = new GithubAPI
      version        : '3.0.0'
      debug          : true
      timeout        : 5000
      headers        :
        'user-agent' : USER_AGENT

    gh.authenticate { type: 'oauth', token }

    return gh
