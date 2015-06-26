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
      'api access'        : ['member','moderator']

    sharedMethods         :
      static              :
        api               :
          (signature Object, Function)


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


  @api = permit 'api access', success: revive

    shouldReviveProvider : no
    shouldHaveOauth      : OAUTH_PROVIDER

  , (client, _options, callback) ->

    { method, options } = _options
    [ base, method ]    = method.split '.'

    # Forcing `per_page` option to max 10 because of max_call_stack_size issue ~ GG
    (options ?= {}).per_page = 10

    gh = initGithubFor client

    try
      gh[base][method] options, callback
    catch err
      callback err
