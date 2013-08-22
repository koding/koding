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
    earnedDiskSpaceInMB :
      type              : Number
    createdAt           :
      type              : Date
      default           : -> new Date

  @set
    sharedMethods     :
      static          : ['redeem', 'fetchRedeemableReferrals', 'fetchReferredAccounts' ]
      instance        : [ ]
    schema            : schema
    relationships     :
      redeemedOn      :
        targetType    : 'JVM'
        as            : 'redeemedOn'

  # Simply find the unused referrals
  # me-[:referer]->JReferral<-[:referred]-JAccount
  @fetchRedeemableReferrals = secure (client, callback)->
    @fetchOwnReferralsIds client, (err, allReferalIds) =>
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
          totalUsedReferalSize = 0
          totalUsedReferalSize += ref.earnedDiskSpaceInMB for ref in usedReferrals

          # find the usable disk sapce
          usableReferralDiskSize = 16000 - totalUsedReferalSize
          # if user consumed their quota return an error
          # this is a special case for used up quota
          return callback new KodingError "You have used your quota for referral system" if usableReferralDiskSize <= 0

          # gather usable referrals
          usableReferrals = []
          for unusedRef in unusedReferrals
            usableReferralDiskSize -= unusedRef.earnedDiskSpaceInMB
            # when we go under the limit, do not continue
            break if usableReferralDiskSize < 0
            usableReferrals.push unusedRef

          callback null, usableReferrals


  @fetchUsedReferrals = (allReferalIds, callback)->
    usedReferralsSelector =
    { sourceId: { $in: allReferalIds }, sourceName: 'JReferral', targetName: 'JVM', as: 'redeemedOn' }

    Relationship.some usedReferralsSelector, {}, (err, usedReferralsRels)=>
      return callback err if err

      usedRefIds = usedReferralsRels.map (rel) -> rel.sourceId

      JReferral.some { _id: $in: usedRefIds }, {}, callback

  @fetchOwnReferralsIds = (client, callback)->
    account = client.connection.delegate

    # find user's relationships as referer to the referral system
    selector = { sourceId: account._id, sourceName: 'JAccount', targetName: 'JReferral', as: 'referer' }

    Relationship.some selector, {}, (err, relationships)=>
      return callback err if err
      return callback null, [] if relationships.length is 0

      allReferalIds = relationships.map (rel) -> "#{rel.targetId}"
      callback null, allReferalIds

  @fetchReferredAccounts = secure (client, callback)->
    @fetchOwnReferralsIds client, (err, allReferalIds) ->
      return callback err if err

      referredSelector =
      { sourceName: 'JAccount', targetId: { $in: allReferalIds }, targetName: 'JReferral', as: 'referred' }

      Relationship.some referredSelector, {}, (err, relationships)=>
        return callback err if err

        accSelector = { _id: $in: relationships.map (rel) -> rel.sourceId }
        JAccount.some accSelector, {}, callback


  @redeem = secure (client, data, callback)->
    {vm, size} = data
    return callback new KodingError "Request is not valid" unless vm and size

    # get redeemable referals
    @fetchRedeemableReferrals client, (err, referrals)=>
      return callback err if err

      # check user has enough credit
      # for loop also checks for 0 length referrals
      totalCredit = 0
      totalCredit += referral.earnedDiskSpaceInMB for referral in referrals

      # if not return an error
      return callback new KodingError "You dont have enough credit to redeem" if size > totalCredit

      # fetch user's vm which will be upgraded
      @fetchUserVM client, vm, (err, jvm)=>
        return callback err if err
        options =
          referrals :referrals
          jvm       :jvm
          size      :size

        @relateReferalsToJVM options, callback

  @relateReferalsToJVM = (options, callback) ->
    {referrals, jvm, size} = options
    # generate the referals to be used for upgrade process
    referalsToBeUsed = []
    addedSize = 0
    for referral in referrals
      break if addedSize >= size
      addedSize += referral.earnedDiskSpaceInMB
      referalsToBeUsed.push referral

    # wrap the callback
    kallback = (err)=>
      return callback err if err

      jvm.update { $inc : 'diskSizeInMB' : addedSize }, (err) ->
        return callback err if err
        res =
          addedSize    : addedSize
          vm           : jvm.hostnameAlias
          newDiskSpace : jvm.diskSizeInMB

        callback null, res

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
        # if referer not fonud then do nothing and return
        return console.error "Session is not defined" if not session
        # if user dont have any referer code then do nothing
        return console.error "no referrer code" unless session.refererCode
        # get referer
        JAccount.one {refererCode: session.refererCode}, (err, referer)->
          # if error occured than do nothing and return
          return console.error "Error while fetching referer", err if err
          # if referer not fonud then do nothing and return
          return console.error "Referer couldnt found" if not referer

          referral = new JReferral { earnedDiskSpaceInMB : 250 }
          referral.save (err) ->
            return console.error err if err
            #add referer as referer to the referral system
            referer.addReferer referral, (err)->
              return console.error err if err
              # add me as referred to the referral system
              me.addReferred referral, (err)->
                return console.error err if err
                console.log "referal saved successfully"
