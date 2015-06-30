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
    # Callback wrapper to add some more
    # functionality to default callback
    cb = (err, response) ->

      if err and err.toJSON?

        err = err.toJSON()

        # Unifying error object, original Error object includes
        # err.message as another object but stringified, so we are
        # making it ready for the client side here. If anything
        # goes wrong it will be send to client as is
        try
          err.details = JSON.parse err.message
          err.message = err.details.message
          delete err.details.message

      callback err, response

    # FIXME Forcing `per_page` option to max 10
    # because of max_call_stack_size issue in Bongo
    # Requires extensive debugging on Bongo.Base ~ GG
    (options ?= {}).per_page = 10

    gh = initGithubFor client

    try
      # TODO We can add a whitelist of accepted methods/bases
      # and check them before we try to execute them ~ CS, GG
      gh[base][method] options, cb
    catch err
      cb err
