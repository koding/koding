request = require 'request'

baseUrl = "https://api.helpscout.net/v1"
key     = "b041e4da61c0934cb73d47e1626098430738b049"

module.exports = (account, req, res) ->

  Payment = require '../../../workers/social/lib/social/models/payment'

  account.fetchUser (err, user)->

    if err? or not user?
      return res.status(401).end()

    {message, subject} = req.body

    if not message or not subject
      return res.status(400).send
        description : "message and subject required"
        error       : "bad_request"

    client = connection: delegate: account
    Payment.subscriptions client, {}, (err, subscription)->

      if err? or not subscription?
      then plan = 'free'
      else plan = subscription.planTitle

      message = """
        ----------------------------------------
        Username   : #{user.username}
        User Agent : #{req.headers['user-agent']}
        User Plan  : #{plan}
        ----------------------------------------


      """ + message

      request
        url           : "#{baseUrl}/conversations.json"
        method        : "POST"
        auth          :
          user        : key
          pass        : "x"
        json          :
          type        : "email"
          customer    :
            email     : user.email
            type      : "customer"
          subject     : subject
          mailbox     :
            id        : 19295
            name      : "Support"
          ,
          threads     : [
            type      : "customer"
            createdBy :
              email   : user.email
              type    : "customer"
            ,
            body      : message
          ]

      , (error, response, body)->

        if error || body
          console.error error, body
          res.status(400).send ok: 0
        else
          res.status(200).send ok: 1
