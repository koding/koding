
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
  JUser    = rekuire 'user/index.coffee'

  # Config
  # ------

  query = type: 'registered'
  skip  = 0

  # Helpers
  # -------

  iterate = (cursor, func, index, callback)->
    cursor.nextObject (err, obj)->
      if err
        callback err, index
      else if obj?
        func obj, index, (err)->
          index++
          iterate cursor, func, index, callback
      else
        callback null, index


  fetchUser  = (acc, callback)->
    selector = { targetId: acc._id, as: 'owner', sourceName: 'JUser' }
    Relationship.one selector, (err, rel) ->
      return callback err   if err
      return callback null  unless rel
      JUser.one {_id: rel.sourceId}, callback


  addMissingRewards = (account, index, callback)->

    referrerUsername = account.profile.nickname

    console.log "##{index} working on", referrerUsername

    query = { referrerUsername }

    originId         = account._id
    type             = "disk"
    unit             = "MB"
    amount           = 500
    sourceCampaign   = "oldkoding"

    JAccount.someData query, {_id:1, profile:1}, {skip}, (err, cursor)->

      return console.log "ERROR: ", err  if err?

      iterate cursor, (referrer, index, callback)->

        fetchUser referrer, (err, user)->

          if err?
            {nickname} = referrer.profile
            console.log "Failed to fetch JUser for #{nickname}, skipping."
            console.log err
            return callback null

          unless user.status is 'confirmed'
            console.log "Referral #{user.username} is not confirmed, skipping."
            return callback null
          else
            console.log "Referral #{user.username} valid, creating reward..."

          providedBy = referrer._id

          reward = new JReward {
            type, unit, amount, sourceCampaign, providedBy, originId
          }

          reward.save (err)->

            if err?.code is 11000
              console.log "
                Reward for #{referrerUsername} from #{user.username}
                was already exists, skipping
              "
            else
              console.warn err  if err?

            options = { unit, type, originId }

            JReward.calculateAndUpdateEarnedAmount options, (err)->
              console.warn err  if err?
              callback null

      , 0, (err, total)->

        if total > 0
          console.log "Processed #{total} referral for #{referrerUsername}"

        callback null


  # Main updater
  # ------------

  JAccount.count query, (err, userCount)->

    console.log "Total #{userCount - skip} accounts found, starting..."

    JAccount.someData query, {_id:1, profile:1}, {skip}, (err, cursor)->

      return console.log "ERROR: ", err  if err?

      iterate cursor, addMissingRewards, skip, (err, total)->

        console.log "FINAL #{total}"
        process.exit 0
