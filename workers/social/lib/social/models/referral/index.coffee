jraphical = require 'jraphical'

JAccount = require '../account'
JUser = require '../user'

KodingError = require '../../error'
{ argv }   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class JReferral extends jraphical.Message

  { Relationship } = jraphical

  { race, secure, daisy, dash, signature } = require 'bongo'

  @share()

  schema =
    # for now we only have disk space
    type              :
      type            : String
    unit              :
      type            : String
    amount            :
      type            : Number
    sourceCampaign    :
      type            : String
      default         : 'register'
    createdAt         :
      type            : Date
      default         : -> new Date

  @set
    sharedMethods     :
      static          :
        addExtraReferral:
          (signature Object, Function)
        redeem:
          (signature Object, Function)
        resetVMDefaults:
          (signature Function)
        fetchRedeemableReferrals:
          (signature Object, Function)
        fetchReferredAccounts:
          (signature Object, Object, Function)
        fetchEarnedSpace:
          (signature Function)
    sharedEvents      :
      static          : []
      instance        : []
    schema            : schema


  @getReferralEarningLimits = (type) ->
    switch type
      when 'disk' then return 17408
      else return console.error 'Unknown referral query limit'

  # Simply find the unused referrals
  # me-[:referrer]->JReferral<-[:referred]-JAccount
  @fetchRedeemableReferrals = secure (client, query, callback) ->
    # check for type of request
    allowedTypes = ['disk']
    return callback new KodingError 'Request is not valid' unless query.type in allowedTypes

    @fetchOwnReferralsIds client, { type: query.type }, {}, (err, allReferalIds) =>
      return callback err if err

      @fetchUsedReferrals allReferalIds, (err, usedReferrals) =>
        return callback err if err

        # aggregate the used referrals
        usedRefIds = []
        usedRefIds.push "#{usedReferral._id}" for usedReferral in usedReferrals when id not in usedRefIds

        # find the diff of unused referrals
        unusedRefIds = []
        unusedRefIds.push id for id in allReferalIds when id not in usedRefIds

        return callback null, [] if unusedRefIds.length < 1

        refSelector = { _id: { $in: unusedRefIds } }
        JReferral.some refSelector, {}, (err, unusedReferrals) =>
          return callback err if err

          # find the total used referred disk spacea
          totalUsedReferalAmount = 0
          totalUsedReferalAmount += ref.amount for ref in usedReferrals

          limit = @getReferralEarningLimits(query.type)
          # find the usable amount
          usableReferralSize = limit - totalUsedReferalAmount
          # if user consumed their quota return an error
          # this is a special case for used up quota
          if usableReferralSize <= 0
            return callback new KodingError 'You have used your quota for referral system'

          # gather usable referrals
          usableReferrals = []
          for unusedRef in unusedReferrals
            usableReferralSize -= unusedRef.amount
            # when we go under the limit, do not continue
            break if usableReferralSize < 0
            usableReferrals.push unusedRef

          callback null, usableReferrals


  @fetchUsedReferrals = (allReferalIds, callback) ->

    usedReferralsSelector = {
      sourceId    : { $in: allReferalIds },
      sourceName  : 'JReferral',
      targetName  : 'JVM',
      as          : 'redeemedOn'
    }

    Relationship.some usedReferralsSelector, {}, (err, usedReferralsRels) ->
      return callback err if err

      usedRefIds = usedReferralsRels.map (rel) -> rel.sourceId

      JReferral.some { _id: { $in: usedRefIds } }, {}, callback

  @fetchOwnReferralsIds = (client, query, options, callback) ->
    account = client.connection.delegate

    # find user's relationships as referrer to the referral system
    selector = {
      sourceId    : account.getId(),
      sourceName  : 'JAccount',
      targetName  : 'JReferral',
      as          : 'referrer'
    }

    Relationship.count selector, (err, count) =>
      return callback err if err
      options.targetOptions = { selector: query }
      @fetchOwnReferralsIdsInBatch count, 100, selector, options, (err, relationships) ->
        allReferalIds = relationships.map (rel) -> "#{rel.targetId}"
        callback null, allReferalIds


  @fetchOwnReferralsIdsInBatch = (totalCount, batchCount, selector, options, callback) ->
    teasers = []
    collectRels = race (i, step, fin) ->
      options.skip  = batchCount * (step - 1)
      options.limit = batchCount
      Relationship.some selector, options, (err, relationships) ->
        if err
          callback err
          fin()
        else if not relationships
          fin()
        else
          teasers.push rel for rel in relationships
          fin()
    , ->
      callback null, teasers
    totalStep = Math.floor(totalCount / batchCount)
    totalStep = if totalStep <= 0 then 1 else totalStep
    while totalStep
      collectRels totalStep
      totalStep--

  @fetchEarnedSpace$ = secure (client, callback) ->
    @fetchEarnedSpace client, callback

  @spaceForReferring = 500

  @fetchEarnedSpace = (client, callback) ->
    @fetchReferredAccounts client, {}, {}, (err, accounts) =>
      return callback err  if err
      callback null, accounts.length * @spaceForReferring

  @fetchReferredAccounts$ = secure (client, query, options, callback) ->
    @fetchReferredAccounts client, query, options, callback

  @fetchReferredAccounts = (client, query, options, callback) ->
    username = client.connection.delegate.profile.nickname
    JAccount.some { referrerUsername : username }, options, callback

  @redeem = secure (client, data, callback) ->
    callback new KodingError 'JReferral::redeem disabled'


  @createUpdateQueryForRedeem = (type, amount) ->
    switch type
      when 'disk' then return { 'diskSizeInMB': amount }
      else
        return console.error 'Invalid type provided'


  @addExtraReferral: secure (client, options, callback) ->
    { delegate } = client.connection
    unless delegate.can 'administer accounts'
      return callback new KodingError 'You can not add extra referral to users'

    { username } = options
    return callback new KodingError 'Please set username'  unless username

    referral = new JReferral
      amount         : options.amount         or 256
      type           : options.type           or 'disk'
      unit           : options.unit           or 'MB'
      sourceCampaign : options.sourceCampaign or 'register'

    referral.save (err) ->
      return callback err if err
      JAccount.one { 'profile.nickname': username }, (err, account) ->
        return callback err if err
        return callback new KodingError 'Account not found'  unless account
        account.addReferrer referral, (err) ->
          return callback err if err
          return callback null, referral


  # this part is only for one time migration,
  # After 100Tb campaign we increased baseVm to 4Gb
  # but now we decided to decrease it back to 3GB
  # now we are gonna add 1Gb as a referral point into our users and
  # when they re-create their VMs it will decrease down to 3G
  # they can redeem their referral point from account page
  # if you see this part after
  # 22 Feb 2014 feel free to remove completely! ~C.S

  @checkFor1GBStatus = (account, callback) ->
    account.fetchReferrers (err, referrers) ->
      return callback err  if err
      for ref in referrers
        { sourceCampaign } = ref
        return callback null, yes  if sourceCampaign is 'baseVMSizeDecrease'
      callback err, no

  @add1GBDisk = (delegate, callback) ->

    @checkFor1GBStatus delegate, (err, used) ->
      return callback err if err
      if used
        console.info "#{delegate.profile.nickname} has already get baseVMSizeDecrease point"
        return callback null, no

      referral = new JReferral {
        type   : 'disk'
        unit   : 'MB'
        amount : 1024
        sourceCampaign : 'baseVMSizeDecrease'
      }
      referral.save (err) ->
        return callback err if err
        #add referrer as referrer to the referral system
        delegate.addReferrer referral, (err) ->
          return callback err if err
          return callback null, yes


