koding = require '../../servers/lib/server/bongo'
fixdata = require '../../workers/social/lib/social/render/datafixes'

koding.once 'dbClientReady', ->
  { JGroup, JSession } = koding.models

  selector = { 'socialApiChannelId' : { $exists: false } }
  JGroup.someData selector, { _id: 1 }, {}, (err, cursor) ->
    return console.error err  if err

    iterate = do (i = 0) ->
      next = -> process.nextTick iterate

      ->
        cursor.nextObject (err, group) ->
          if err
            console.error 'error: cursor next object fetcher failed'
            console.error JSON.stringify err
            return process.exit 1

          unless group
            console.log 'finished'
            return process.exit 0

          JGroup.one { _id: group._id }, (err, gr) ->
            if err
              console.log 'err while getting acc', group._id, err
              next()
            else
              return next() unless gr
              return next() if gr.slug in [ 'guests', 'koding' ]
              console.log "processing #{gr.slug}"
              gr.fetchAdmin (err, admin) ->
                if err
                  console.error "err while fetching admin for #{gr.slug}", err
                  return next()

                unless admin
                  console.error "couldnt find admin for #{gr.slug}"
                  return next()

                sessionData = { username: admin.profile.nickname, groupName: group.slug }
                JSession.fetchSessionByData sessionData, (err, session) ->
                  return console.error 'err while fetching session', err  if err
                  return console.error 'couldnt find a session'  unless session

                  context = { group: gr.slug }
                  koding.fetchClient session.clientId, context, (client) ->
                    fixdata client, gr, next

    iterate()
