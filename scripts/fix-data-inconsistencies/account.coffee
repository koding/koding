path = require 'path'
Bongo   = require 'bongo'
KONFIG = require 'koding-config-manager'

modelPath = '../../workers/social/lib/social'
rekuire   = (p) -> require path.join modelPath, p

fixdata = rekuire 'render/datafixes'
JAccount = rekuire 'models/account'

koding = new Bongo
  root   : __dirname
  mongo  : "mongodb://#{KONFIG.mongo}"
  models : '../../workers/social/lib/social/models'

koding.once 'dbClientReady', ->

  JAccount.someData {}, { _id: 1 }, {}, (err, cursor) ->
    return console.error err  if err

    iterate = do (i = 0) ->
      next = -> process.nextTick iterate

      ->
        cursor.nextObject (err, account) ->
          if err
            console.error 'error: cursor next object fetcher failed'
            console.error JSON.stringify err
            return process.exit 1

          console.log account
          unless account
            console.log 'finished'
            return process.exit 0

          JAccount.one { _id: account._id }, ( err, acc ) ->
            if err
              console.log 'err while getting acc', account._id, err
              next()
            else
              fixdata acc, null, next

    iterate()
