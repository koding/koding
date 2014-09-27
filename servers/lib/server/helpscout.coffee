request = require 'request'

baseUrl = "https://api.helpscout.net/v1"
key     = "3673d12d3a1b45dc8fd3e0fc4e1a586e1f1918b7"

module.exports = (account, req, res) ->

  Payment = require '../../../workers/social/lib/social/models/payment'

  account.fetchUser (err, user)->

    if err? or not user?
      return res.send 401

    {message, subject} = req.body

    if not message or not subject
      return res.send 400,
        description : "message and subject required"
        error       : "bad_request"

    client = connection: delegate: account
    Payment.subscriptions client, {}, (err, subscription)->

      if err? or not subscription?
      then plan = 'free'
      else plan = subscription.planTitle

      message += """

        ----------------------------------------
        Username   : #{user.username}
        User Agent : #{req.headers['user-agent']}
        User Plan  : #{plan}
      """

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
          res.send 400, ok: 0
        else
          res.send 200, ok: 1