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
        addExtraReferral:
          (signature Object, Function)
        fetchClaimedAmount:
          (signature Object, Function)
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


  @fetchReferredAccounts$ = secure (client, query, options, callback)->
    @fetchReferredAccounts client, query, options, callback

  @fetchReferredAccounts = (client, query, options, callback)->
    username = client.connection.delegate.profile.nickname
    JAccount.some { referrerUsername : username }, options, callback


  @addExtraReferral = secure (client, options, callback)->

    {delegate} = client.connection
    unless delegate.can 'administer accounts'
      return callback {message: "You can not add extra referral to users"}

    {username} = options
    return callback {message: "Please set username"}  unless username

    referral = new JReferral
      amount         : options.amount         or 256
      type           : options.type           or "disk"
      unit           : options.unit           or "MB"
      sourceCampaign : options.sourceCampaign or "register"

    referral.save (err) ->
      return callback err if err
      JAccount.one {'profile.nickname': username}, (err, account)->
        return callback err if err
        return callback {message:"Account not found"} unless account
        account.addReferrer referral, (err)->
          return callback err if err
          return callback null, referral


  useDefault = (options)->

    options.unit ?= "MB"
    options.type ?= "disk"

    return options


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
    options.originId = originId = client.connection.delegate.getId()

    fetchClaimedReferral options, (err, claimedReferral)->
      return callback err  if err?

      if claimedReferral?
        return callback null, claimedReferral.amount

      JReferral.calculateAndUpdateClaimedAmount options, callback


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
