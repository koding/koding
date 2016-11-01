request  = require 'request'
KONFIG   = require 'koding-config-manager'

module.exports = (account, req, res) ->

  { apiKey, baseUrl } = KONFIG.helpscout  if KONFIG.helpscout

  if not apiKey or not baseUrl
    errorText = 'HelpScout is disabled because of missing configuration'
    console.warn errorText
    return res.status(400).send
      description : errorText
      error       : 'bad_request'

  account.fetchUser (err, user) ->

    if err? or not user?
      return res.status(401).end()

    { message, subject } = req.body

    if not message or not subject
      return res.status(400).send
        description : 'message and subject required'
        error       : 'bad_request'

    client = { connection: { delegate: account } }
    plan = 'free'

    message = """
      Username   : #{user.username}
      User Agent : #{req.headers['user-agent']}
      User Plan  : #{plan}
      ----------------------------------------


    """ + message

    request
      url           : "#{baseUrl}/conversations.json"
      method        : 'POST'
      auth          :
        user        : key
        pass        : 'x'
      json          :
        type        : 'email'
        customer    :
          email     : user.email
          type      : 'customer'
        subject     : subject
        mailbox     :
          id        : 19295
          name      : 'Support'
        ,
        tags	      : ["Plan->#{plan}"]
        ,
        threads     : [
          type      : 'customer'
          createdBy :
            email   : user.email
            type    : 'customer'
          ,
          body      : message
        ]

    , (error, response, body) ->

      if error or body
        console.error error, body
        res.status(400).send { ok: 0 }
      else
        res.status(200).send { ok: 1 }
