koding = require '../../servers/lib/server/bongo'
fixdata = require '../../workers/social/lib/social/render/datafixes'

koding.once 'dbClientReady', ->
  { JAccount, JSession } = koding.models

  selector = { 'socialApiId': { $exists: false } }
  JAccount.someData selector, { _id: 1 }, {}, (err, cursor) ->
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

          JAccount.one { _id: account._id }, (err, acc) ->
            if err
              console.log 'err while getting acc', account._id, err
              next()
            else
              return next() unless acc
              sessionData = { username: acc.profile.nickname, groupName: 'koding' }
              JSession.fetchSessionByData sessionData, (err, session) ->
                return console.error 'err while fetching session', err  if err
                return console.error 'couldnt find a session'  unless session

                context = { group: 'koding' }
                koding.fetchClient session.clientId, context, (client) ->
                  fixdata client, null, next

    iterate()
