jraphical = require 'jraphical'

JAccount = require '../account'
JVM = require '../vm'
JSession = require '../session'
KodingError = require '../../error'


module.exports = class JReferral extends jraphical.Message

  {Relationship} = jraphical

  {secure, dash} = require 'bongo'

  @share()

  schema =
    # for now we only have disk space
    type              :
      type            : String
    unit              :
      type            : String
    amount            :
      type            : Number
    createdAt         :
      type            : Date
      default         : -> new Date

  @set
    sharedMethods     :
      static          : ['redeem', 'fetchRedeemableReferrals', 'fetchReferredAccounts' ]
      instance        : [ ]
    schema            : schema
    relationships     :
      redeemedOn      :
        targetType    : 'JVM'
        as            : 'redeemedOn'

  @getReferralEarningLimits = (type) ->
    switch type
      when "disk" then return 16000
      else return console.error "Unknown referral query limit"

  # Simply find the unused referrals
  # me-[:referrer]->JReferral<-[:referred]-JAccount
  @fetchRedeemableReferrals = secure (client, query, callback)->
    # check for type of request
    allowedTypes = ["disk"]
    return callback new KodingError "Request is not valid" unless query.type in allowedTypes

    # add better limit option here
    options = { limit : 100 }
    @fetchOwnReferralsIds client, { type: query.type }, options, (err, allReferalIds) =>
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

        refSelector = { _id: $in: unusedRefIds }
        JReferral.some refSelector, {}, (err, unusedReferrals)=>
          return callback err if err

          # find the total used referred disk spacea
          totalUsedReferalAmount = 0
          totalUsedReferalAmount += ref.amount for ref in usedReferrals

          limit = @getReferralEarningLimits(query.type)
          # find the usable amount
          usableReferralSize = limit - totalUsedReferalAmount
          # if user consumed their quota return an error
          # this is a special case for used up quota
          return callback new KodingError "You have used your quota for referral system" if usableReferralSize <= 0

          # gather usable referrals
          usableReferrals = []
          for unusedRef in unusedReferrals
            usableReferralSize -= unusedRef.amount
            # when we go under the limit, do not continue
            break if usableReferralSize < 0
            usableReferrals.push unusedRef

          callback null, usableReferrals


  @fetchUsedReferrals = (allReferalIds, callback)->

    usedReferralsSelector = {
      sourceId    : { $in: allReferalIds },
      sourceName  : 'JReferral',
      targetName  : 'JVM',
      as          : 'redeemedOn'
    }

    Relationship.some usedReferralsSelector, {}, (err, usedReferralsRels)=>
      return callback err if err

      usedRefIds = usedReferralsRels.map (rel) -> rel.sourceId

      JReferral.some { _id: $in: usedRefIds }, {}, callback

  @fetchOwnReferralsIds = (client, query, options, callback)->
    account = client.connection.delegate

    # find user's relationships as referrer to the referral system
    selector = {
      sourceId    : account.getId(),
      sourceName  : 'JAccount',
      targetName  : 'JReferral',
      as          : 'referrer'
    }

    options.limit ?= 10
    options.targetOptions = { selector: query }

    Relationship.some selector, options, (err, relationships)=>
      return callback err if err
      return callback null, [] if relationships.length is 0

      allReferalIds = relationships.map (rel) -> "#{rel.targetId}"
      callback null, allReferalIds

  @fetchReferredAccounts = secure (client, query, options, callback)->
    @fetchOwnReferralsIds client, query, options, (err, allReferalIds) ->
      return callback err if err

      referredSelector = {
        sourceName: 'JAccount',
        targetId: { $in: allReferalIds },
        targetName: 'JReferral',
        as: 'referred'
      }

      # no need to add limit here, because in fetchOwnReferralsIds method there is limit,
      # this is a subset of it, so this will be lte than ownReferralsIds
      Relationship.some referredSelector, {}, (err, relationships)=>
        return callback err if err

        accSelector = { _id: $in: relationships.map (rel) -> rel.sourceId }
        JAccount.some accSelector, {}, callback


  @redeem = secure (client, data, callback)->
    {vm, size, type} = data
    return callback new KodingError "Request is not valid" unless vm and size

    # get redeemable referals
    @fetchRedeemableReferrals client, {type}, (err, referrals)=>
      return callback err if err

      # check user has enough credit
      # for loop also checks for 0 length referrals
      totalCredit = 0
      totalCredit += referral.amount for referral in referrals

      # if not return an error
      return callback new KodingError "You dont have enough credit to redeem" if size > totalCredit

      # fetch user's vm which will be upgraded
      @fetchUserVM client, vm, (err, jvm)=>
        return callback err if err
        options =
          referrals :referrals
          jvm       :jvm
          size      :size
          type      :type

        @relateReferalsToJVM options, callback

  @createUpdateQueryForRedeem = (type, amount) ->
    switch type
      when "disk" then return 'diskSizeInMB': amount
      else
        return console.error "Invalid type provided"

  @relateReferalsToJVM = (options, callback) ->
    {referrals, jvm, size, type} = options
    # generate the referals to be used for upgrade process
    referalsToBeUsed = []
    addedSize = 0
    for referral in referrals
      break if addedSize >= size
      addedSize += referral.amount
      referalsToBeUsed.push referral

    # wrap the callback
    kallback = (err)=>
      return callback err if err

      returnValue =
        addedSize    : addedSize
        vm           : jvm.hostnameAlias
        type         : type
        unit         : referrals.first.unit

      updateQuery = @createUpdateQueryForRedeem type

      jvm.update { $inc: updateQuery }, (err) ->
        return callback err if err

        callback null, returnValue

    queue = referalsToBeUsed.map (ref)=>=>
      ref.addRedeemedOn jvm, (err)->
        return kallback err if err
        queue.fin()

    dash queue, kallback


  @fetchUserVM = (client, vm, callback)->
    account = client.connection.delegate

    # get the user to fetch his/her VMs
    account.fetchUser (err, user) ->
      return callback err  if err
      selector =
        users:
          $elemMatch:
            id: user.getId()
        hostnameAlias: vm
      # get user's vms
      JVM.one selector, (err, jvm)->
        return callback err  if err
        return callback new KodingError "#{vm} is not found" unless jvm
        callback null, jvm

  do =>
    JAccount.on 'AccountRegistered', (me)->
      return console.error "Account is not defined in event" unless me
      JSession.one {username: me.profile.nickname }, (err, session) =>
        # if error occured than do nothing and return
        return console.error "Session fetching caused error", err if err
        # if referrer not fonud then do nothing and return
        return console.error "Session is not defined" if not session
        # if user dont have any referrer code then do nothing
        return console.error "no referrer code" unless session.referrerCode
        # get referrer
        JAccount.one {'profile.nickname': session.referrerCode}, (err, referrer)->
          # if error occured than do nothing and return
          return console.error "Error while fetching referrer", err if err
          # if referrer not fonud then do nothing and return
          return console.error "Referrer couldnt found" if not referrer

          data =
            type   : "disk"
            unit   : "MB"
            amount : 250

          referral = new JReferral data
          referral.save (err) ->
            return console.error err if err
            #add referrer as referrer to the referral system
            referrer.addReferrer referral, (err)->
              return console.error err if err
              # add me as referred to the referral system
              me.addReferred referral, (err)->
                return console.error err if err
                console.log "referal saved successfully"
