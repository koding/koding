fixdata = require '../../workers/social/lib/social/render/datafixes'
koding = require '../../servers/lib/server/bongo'

koding.once 'dbClientReady', ->
  { JGroup } = koding.models

  JGroup.someData {}, { _id: 1 }, {}, (err, cursor) ->
    return console.error err  if err

    iterate = do (i = 0) ->
      next = -> process.nextTick iterate

      ->
        cursor.nextObject (err, group) ->
          if err
            console.error 'error: cursor next object fetcher failed'
            console.error JSON.stringify err
            return process.exit 1

          console.log group
          unless group
            console.log 'finished'
            return process.exit 0

          JGroup.one { _id: group._id }, ( err, gr ) ->
            if err
              console.log 'err while getting acc', group._id, err
              next()
            else
              fixdata null, gr, next

    iterate()
