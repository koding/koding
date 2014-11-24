jraphical   = require 'jraphical'
KodingError = require '../../error'

JAccount    = require '../account'
JUser       = require '../user'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JReward extends jraphical.Message

  {Relationship} = jraphical

  {race, secure, daisy, dash, signature, ObjectId} = require 'bongo'

  @share()

  @set

    sharedMethods     :

      static          :
        addCustomReward:
          (signature Object, Function)
        fetchEarnedAmount:
          (signature Object, Function)
        fetchReferrals:
          (signature Object, Object, Function)
        fetchReferredAccounts:
          (signature Object, Object, Function)

    sharedEvents      :
      static          : []
      instance        : []

    schema            :
      # for now we only have disk space
      type            :
        type          : String
      unit            :
        type          : String
      amount          :
        type          : Number
      sourceCampaign  :
        type          : String
        default       : "register"
      createdAt       :
        type          : Date
        default       : -> new Date
      providedBy      :
        type          : ObjectId
      originId        :
        type          : ObjectId
        required      : yes


  # Helpers
  # -------

  useDefault = (options)->

    options.unit ?= "MB"
    options.type ?= "disk"

    return options


  fetchEarnedReward = (options, callback)->

    { originId, unit, type } = useDefault options

    JEarnedReward = require './earnedreward'
    JEarnedReward.one { originId, unit, type }, callback


  aggregateAmount = (options, callback)->

    { originId, unit, type } = useDefault options

    JReward.aggregate
      $match     : { unit, type, originId }
    ,
      $group     :
        _id      : "$originId"
        total    :
          $sum   : "$amount"

    , (err, res)->

      return callback err      if err?
      return callback null, 0  unless res?

      callback null, res[0]?.total ? 0



  # Private Methods
  # ---------------

  @updateEarnedAmount = (options, callback)->

    { originId, unit, type, amount } = useDefault options

    JEarnedReward = require './earnedreward'
    JEarnedReward.update { originId, unit, type }
    ,
      $set: { amount }
    ,
      upsert: yes
    ,
      (err)-> callback err


  @calculateAndUpdateEarnedAmount = (options, callback)->

    options = useDefault options

    aggregateAmount options, (err, amount)->

      return callback err  if err?

      options.amount = amount

      JReward.updateEarnedAmount options, (err)->
        return callback err  if err?

        callback null, amount



  # Shared Methods
  # --------------

  @addCustomReward = secure (client, options, callback)->

    {delegate} = client.connection
    unless delegate.can 'administer accounts'
      return callback new KodingError "Not allowed to create custom rewards."

    { username, type, unit } = useDefault options

    unless username
      return callback new KodingError "Please set username"

    providedBy = client.connection.delegate.getId()

    JAccount.one 'profile.nickname': username, (err, account)->

      return callback err if err

      unless account
        return callback new KodingError "Account not found"

      originId = account.getId()

      reward = new JReward {
        amount         : options.amount         or 512
        sourceCampaign : options.sourceCampaign or "register"
        providedBy, originId, type, unit
      }

      reward.save (err)->

        return callback err if err

        options = { unit, type, originId }

        JReward.calculateAndUpdateEarnedAmount options, (err)->

          return callback err if err
          callback null, reward


  @fetchEarnedAmount = secure (client, options, callback)->

    options = useDefault options
    options.originId = client.connection.delegate.getId()

    fetchEarnedReward options, (err, earnedReward)->
      return callback err  if err?

      if earnedReward?
        return callback null, earnedReward.amount

      callback null, 0

      # We can manually call this if we need.
      # JReward.calculateAndUpdateEarnedAmount options, callback


  @fetchReferrals = secure (client, query, options, callback)->
    query.originId = client.connection.delegate.getId()
    JReward.some query, options, callback


  @fetchReferredAccounts = secure (client, query, options, callback)->
    username = client.connection.delegate.profile.nickname
    JAccount.some { referrerUsername : username }, options, callback



  # Background Processes
  # --------------------

  do ->

    JAccount.on 'AccountRegistered', (me, referrerCode)->

      return console.error "Account is not defined in event"  unless me
      return  unless referrerCode

      {nickname} = me.profile
      if nickname is referrerCode
        return console.error "User (#{nickname}) tried to refer themself."

      me.update $set: referrerUsername: referrerCode, (err)->

        unless err
          console.log "reward saved for #{nickname} from #{referrerCode}"


    persistRewards = (campaign, source, target, callback)->

      reward = null

      type     = campaign.type
      unit     = campaign.unit
      originId = target.getId()

      queue = [

        ->

          reward = new JReward {
            amount         : campaign.perEventAmount
            sourceCampaign : campaign.name
            providedBy     : source.getId()
            originId, type, unit
          }

          reward.save (err) ->
            return callback err  if err
            queue.next()

        ->

          options = { originId, type, unit }

          JReward.calculateAndUpdateEarnedAmount options, (err)->

            return callback err  if err
            queue.next()

        ->

          campaign.increaseGivenAmount (err)->
            console.error "Couldn't increase given amount:", err  if err?
            callback null

      ]

      daisy queue


    JRewardCampaign = require "./rewardcampaign"

    JUser.on 'EmailConfirmed', (user)->

      unless user?
        return console.warn "User is not defined in '#{EmailConfirmed}' event"

      me       = null
      referrer = null
      campaign = null

      queue = [
        ->

          JRewardCampaign.isValid "register", (err, res)->

            return console.error err  if err
            return  unless res.isValid

            campaign = res.campaign
            queue.next()

        ->

          user.fetchOwnAccount (err, myAccount)->
            return console.error err  if err
            # if account not fonud then do nothing and return
            return console.error "Account couldn't found" unless myAccount

            me = myAccount
            queue.next()

        ->

          unless referrerUsername = me.referrerUsername
            return console.info "User doesn't have any referrer"

          if me.referralUsed
            return console.info "User already get the referrer"

          # get referrer
          JAccount.one 'profile.nickname': referrerUsername, (err, _referrer)->

            if err
              # if error occurred than do nothing and return
              return console.error "Error while fetching referrer", err

            unless _referrer
              # if referrer not fonud then do nothing and return
              return console.error "Referrer couldnt found"

            referrer = _referrer
            queue.next()

        ->

          me.update $set: "referralUsed": yes, (err)->
            return console.error err if err
            queue.next()

        ->

          persistRewards campaign, referrer, me, (err)->
            return console.error err if err
            queue.next()

        ->

          persistRewards campaign, me, referrer, (err)->
            return console.error err if err
            queue.next()

      ]

      daisy queue
