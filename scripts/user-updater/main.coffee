
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

  JAccount  = rekuire 'account.coffee'
  JReward   = rekuire 'rewards/index.coffee'
  JReferral = rekuire 'referral/index.coffee'
  JUser     = rekuire 'user/index.coffee'

  userCache = {}

  # Config
  # ------

  query = { type: "disk", unit: "MB" }
  skip  = 0

  # Helpers
  # -------

  logError = (err, index)->
    console.log "ERROR on #{index}. >", err  if err?

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


  fetchAccount = (_id, cb)->

    if cached = userCache[_id]
      return cb null, cached

    JAccount.one {_id}, (err, account)->
      return cb err  if err
      return cb {message: "no account found"}  unless account

      JUser.one {username: account.profile.nickname}, (err, user)->
        return cb err  if err
        return cb {message: "no user found"}  unless user

        cb null, userCache[_id] = {user, account}


  fetchMembers = (referral, as, cb)->

    selector = {targetId: referral._id, as}

    Relationship.one selector, (err, rel)->
      return cb err  if err
      return cb {message: "no relationship found"}  unless rel

      fetchAccount rel.sourceId, (err, member)->
        return cb err  if err
        cb null, member


  fetchDamn = (referral, cb)->

    fetchMembers referral, "referrer", (err, referrer)->
      return cb err  if err

      fetchMembers referral, "referred", (err, referred)->
        return cb err  if err

        cb null, {referrer, referred}


  createMissingReward = (referral, {referrer, referred}, callback)->

    type           = "disk"
    unit           = "MB"
    amount         = referral.amount
    sourceCampaign = "oldkoding"

    console.log "Referrer #{referrer.user.username} valid, creating reward..."

    providedBy = referrer.account._id
    originId   = referred.account._id

    reward = new JReward {
      type, unit, amount, sourceCampaign, providedBy, originId
    }

    reward.save (err)->

      if err?.code is 11000
        console.log "
          Reward for #{referrer.user.username} from #{referred.user.username}
          was already exists, skipping
        "
      else if err
        console.warn err
        return callback null

      options = { unit, type, originId }

      JReward.calculateAndUpdateEarnedAmount options, (err)->
        console.warn err  if err?
        callback null


  addMissingRewards = (referral, index, callback)->

    console.log "Working on #{index}. referral"

    fetchDamn referral, (err, res) ->

      if err
        logError err, index
        return callback null

      {referrer, referred} = res

      createMissingReward referral, {referrer, referred}, (err)->
        logError err, index

        [referrer, referred] = [referred, referrer]

        createMissingReward referral, {referrer, referred}, (err)->
          logError err, index

          callback null


  # Main updater
  # ------------

  JReferral.count query, (err, referralCount)->

    console.log "Total #{referralCount - skip} referrals found, starting..."

    JReferral.someData query, {_id: 1, amount: 1}, {skip}, (err, cursor)->

      return console.log "ERROR: ", err  if err?

      iterate cursor, addMissingRewards, skip, (err, total)->

        console.log "ERROR >>", err  if err?
        console.log "FINAL #{total}"
        process.exit 0
