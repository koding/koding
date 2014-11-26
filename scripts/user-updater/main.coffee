
Bongo = require 'bongo'
{Relationship} = require 'jraphical'

{ join: joinPath } = require 'path'

argv      = require('minimist') process.argv
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")

mongo     = "mongodb://#{ KONFIG.mongo }"
modelPath = '../../workers/social/lib/social/models'
rekuire   = (p)-> require joinPath modelPath, p

koding = new Bongo
  root   : __dirname
  mongo  : mongo
  models : modelPath

console.log "Trying to connect #{mongo} ..."

koding.once 'dbClientReady', ->

  JAccount = rekuire 'account.coffee'
  JReward  = rekuire 'rewards/index.coffee'

  fetchUser = (acc, callback)->
    JUser   = rekuire 'user/index.coffee'

    selector = { targetId: acc._id, as: 'owner', sourceName: 'JUser' }
    Relationship.one selector, (err, rel) ->
      return callback err   if err
      return callback null  unless rel
      JUser.one {_id: rel.sourceId}, callback


  gskip = 0

  JAccount.count {type:'registered'}, (err, total)->
    return console.warn err  if err?

    limit = 100

    console.log "Total #{total} users found, updating..."

    fetcher = (skip)->

      dindex = 0
      index  = skip

      JAccount.each { type:'registered' }, {}, {skip, limit}, (err, account)->

        return console.warn err  if err?
        return  unless account?

        index++
        console.log "Working on #{index}. user"  if index % 10 is 0

        originId         = account._id
        referrerUsername = account.profile.nickname
        type             = "disk"
        unit             = "MB"
        amount           = 500
        sourceCampaign   = "register"

        JAccount.each { referrerUsername }, {}, { limit: 40 }, (err, referrer)->

          console.warn err  if err?

          unless referrer
            options = { unit, type, originId }
            console.log "updating rewards for #{referrerUsername}"
            JReward.calculateAndUpdateEarnedAmount options, (err)->
              console.log "rewards updated for #{referrerUsername}", err
            return

          providedBy = referrer._id

          fetchUser referrer, (err, user)->

            console.log "Found user:", user.username, user.status
            return  unless user.status is 'confirmed'

            reward = new JReward {
              type, unit, amount, sourceCampaign, providedBy, originId
            }

            reward.save (err)->
              console.warn err  if err?

          dindex++

          if dindex is limit
            console.log "#{index} users updated."
            console.log "Moving to next batch."
            fetcher skip + limit

          else if skip >= total
            console.log "ALL DONE"
            process.exit 0


    fetcher gskip