jraphical   = require 'jraphical'
KodingError = require '../../error'

JAccount    = require '../account'
JUser       = require '../user'

{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JReferral extends jraphical.Message

  {Relationship} = jraphical

  {race, secure, daisy, dash, signature, ObjectId} = require 'bongo'

  @share()

  @set

    sharedMethods     :

      static          :
        addCustomReferral:
          (signature Object, Function)
        fetchClaimedAmount:
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
      referredBy      :
        type          : ObjectId
      originId        :
        type          : ObjectId
        required      : yes


  useDefault = (options)->

    options.unit ?= "MB"
    options.type ?= "disk"

    return options


  @addCustomReferral = secure (client, options, callback)->

    {delegate} = client.connection
    unless delegate.can 'administer accounts'
      return callback new KodingError "You can not add extra referral to users"

    { username, type, unit } = useDefault options

    unless username
      return callback new KodingError "Please set username"

    referredBy = client.connection.delegate.getId()

    JAccount.one 'profile.nickname': username, (err, account)->

      return callback err if err

      unless account
        return callback new KodingError "Account not found"

      originId = account.getId()

      referral = new JReferral {
        amount         : options.amount         or 512
        sourceCampaign : options.sourceCampaign or "register"
        referredBy, originId, type, unit
      }

      referral.save (err) ->

        return callback err if err

        options = { unit, type, originId }

        JReferral.calculateAndUpdateClaimedAmount options, (err)->

          return callback err if err
          callback null, referral


  @fetchReferredAccounts = secure (client, query, options, callback)->
    username = client.connection.delegate.profile.nickname
    JAccount.some { referrerUsername : username }, options, callback


  @fetchReferrals = secure (client, query, options, callback)->
    query.originId = client.connection.delegate.getId()
    JReferral.some query, options, callback


  fetchClaimedReferral = (options, callback)->

    { originId, unit, type } = useDefault options

    JClaimedReferral = require './claimedreferral'
    JClaimedReferral.one { originId, unit, type }, callback


  @updateClaimedAmount = (options, callback)->

    { originId, unit, type, amount } = useDefault options

    JClaimedReferral = require './claimedreferral'
    JClaimedReferral.update { originId, unit, type }
    ,
      $set: { amount }
    ,
      upsert: yes
    ,
      (err)-> callback err


  aggregateAmount = (options, callback)->

    { originId, unit, type } = useDefault options

    JReferral.aggregate
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


  @calculateAndUpdateClaimedAmount = (options, callback)->

    options = useDefault options

    aggregateAmount options, (err, amount)->

      return callback err  if err?

      options.amount = amount

      JReferral.updateClaimedAmount options, (err)->
        return callback err  if err?

        callback null, amount


  @fetchClaimedAmount = secure (client, options, callback)->

    options = useDefault options
    options.originId = client.connection.delegate.getId()

    fetchClaimedReferral options, (err, claimedReferral)->
      return callback err  if err?

      if claimedReferral?
        return callback null, claimedReferral.amount

      callback null, 0

      # We can manually call this if we need.
      # JReferral.calculateAndUpdateClaimedAmount options, callback


  do ->

    JAccount.on 'AccountRegistered', (me, referrerCode)->

      return console.error "Account is not defined in event"  unless me
      return  unless referrerCode

      {nickname} = me.profile
      if nickname is referrerCode
        return console.error "User (#{nickname}) tried to refer themself."

      me.update $set: referrerUsername: referrerCode, (err)->

        unless err
          console.log "referal saved for #{nickname} from #{referrerCode}"


    persistReferrals = (campaign, source, target, callback)->

      referral = null

      type     = campaign.campaignType
      unit     = campaign.campaignUnit
      originId = target.getId()

      queue = [

        ->

          referral = new JReferral {
            amount         : campaign.campaignPerEventAmount or 256
            sourceCampaign : campaign.name
            referredBy     : source.getId()
            originId, type, unit
          }

          referral.save (err) ->
            return callback err  if err
            queue.next()

        ->

          options = { originId, type, unit }

          JReferral.calculateAndUpdateClaimedAmount options, (err)->

            return callback err  if err
            queue.next()

        ->

          campaign.increaseGivenAmountSpace (err)->
            console.error "Couldnt decrease the left space", err  if err?
            callback null

      ]

      daisy queue


    JReferralCampaign = require "./campaign"

    JUser.on 'EmailConfirmed', (user)->

      unless user?
        return console.warn "User is not defined in '#{EmailConfirmed}' event"

      me       = null
      referrer = null
      campaign = null

      queue = [
        ->

          JReferralCampaign.isCampaignValid (err, res)->

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

          persistReferrals campaign, referrer, me, (err)->
            return console.error err if err
            queue.next()

        ->

          persistReferrals campaign, me, referrer, (err)->
            return console.error err if err
            queue.next()

      ]

      daisy queue
