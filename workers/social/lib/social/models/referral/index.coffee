jraphical = require 'jraphical'

JAccount = require '../account'
JUser = require '../user'
JVM = require '../vm'
KodingError = require '../../error'


module.exports = class JReferral extends jraphical.Message

  {Relationship} = jraphical

  {race, secure, dash, signature} = require 'bongo'

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
      static          :
        redeem:
          (signature Object, Function)
        add1GBDisk:
          (signature Function)
        fetchTBCampaign:
          (signature Function)
        isCampaingValid:
          (signature Function)
        resetVMDefaults:
          (signature Function)
        fetchRedeemableReferrals:
          (signature Object, Function)
        fetchReferredAccounts:
          (signature Object, Object, Function)
    sharedEvents      :
      static          : []
      instance        : []
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

    Relationship.count selector, (err, count) =>
      return callback err if err
      options.targetOptions = { selector: query }
      @fetchOwnReferralsIdsInBatch count, 100, selector, options, (err, relationships)->
        allReferalIds = relationships.map (rel) -> "#{rel.targetId}"
        callback null, allReferalIds


  @fetchOwnReferralsIdsInBatch = (totalCount, batchCount, selector, options, callback)->
    teasers = []
    collectRels = race (i, step, fin)->
      options.skip  = batchCount * (step - 1)
      options.limit = batchCount
      Relationship.some selector, options, (err, relationships)=>
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
    totalStep = Math.floor(totalCount/batchCount)
    totalStep = if totalStep <= 0 then 1 else totalStep
    while totalStep
      collectRels totalStep
      totalStep--

  @fetchReferredAccounts = secure (client, query, options, callback)->
    username = client.connection.delegate.profile.nickname
    JAccount.some { referrerUsername : username }, options, callback

  @redeem = secure (client, data, callback)->
    {vmName, size, type} = data
    return callback new KodingError "Request is not valid" unless vmName and size

    # get redeemable referals
    @fetchRedeemableReferrals client, {type}, (err, referrals)=>
      return callback err if err

      # check user has enough credit
      # for loop also checks for 0 length referrals
      totalCredit = 0
      totalCredit += referral.amount for referral in referrals

      # if not return an error
      return callback new KodingError "You dont have enough credit to redeem" if size > totalCredit

      # fetch user's vmName which will be upgraded
      @fetchUserVM client, vmName, (err, vm)=>
        return callback err if err
        options =
          referrals :referrals
          vm        :vm
          size      :size
          type      :type

        @relateReferalsToJVM options, callback

  @createUpdateQueryForRedeem = (type, amount) ->
    switch type
      when "disk" then return 'diskSizeInMB': amount
      else
        return console.error "Invalid type provided"

  @relateReferalsToJVM = (options, callback) ->
    {referrals, vm, size, type} = options
    # generate the referals to be used for upgrade process
    referralsToBeUsed = []
    addedSize = 0
    for referral in referrals
      break if addedSize >= size
      addedSize += referral.amount
      referralsToBeUsed.push referral

    # wrap the callback
    kallback = (err)=>
      return callback err if err

      returnValue =
        addedSize    : addedSize
        vm           : vm.hostnameAlias
        type         : type
        unit         : referrals.first.unit

      updateQuery = @createUpdateQueryForRedeem type, addedSize

      vm.update { $inc: updateQuery }, (err) ->
        return callback err if err
        callback null, returnValue

    queue = referralsToBeUsed.map (ref)=>=>
      ref.addRedeemedOn vm, (err)->
        return kallback err if err
        queue.fin()

    dash queue, kallback

  @checkFor1GBStatus = (delegate, callback)->
    delegate.fetchReferrers (err, referrers)=>
      return callback err  if err
      for ref in referrers
        {type, unit, amount} = ref
        return callback null, yes  if type is "disk" and unit is "MB" and amount is CAMPAIGN_DISK_SIZE_IN_MB
      callback err, no

  @add1GBDisk = secure (client, callback)->
    {delegate} = client.connection
    @checkFor1GBStatus delegate, (err, used) =>
      return callback new Error "An error occured while trying to add your 1GB please try again" if err
      if used
        err = new Error "You have already redeemed your 1GB extra storage"
        err.code = 600
        return callback err

      referral = new JReferral { type: "disk", unit: "MB", amount: CAMPAIGN_DISK_SIZE_IN_MB }
      referral.save (err) ->
        return callback err if err
        #add referrer as referrer to the referral system
        delegate.addReferrer referral, (err)->
          return callback err if err
          return callback null, yes

  @fetchUserVM = (client, vmName, callback)->
    account = client.connection.delegate

    # get the user to fetch his/her VMs
    account.fetchUser (err, user) ->
      return callback err  if err
      selector =
        users:
          $elemMatch:
            id: user.getId()
        hostnameAlias: vmName
      # get user's vms
      JVM.one selector, (err, vm)->
        return callback err  if err
        return callback new KodingError "#{vm} is not found" unless vm
        callback null, vm

  CAMPAIGN_NAME                   = "100_TB_CAMPAIGN"
  CAMPAIGN_TOTAL_DISK_SIZE_IN_MB  = 1024*1024*100 # 100TB
  CAMPAIGN_DISK_SIZE_IN_MB        = 1024
  CAMPAIGN_START_DATE             = new Date("Jan 28 2014 16:00:00 GMT")
  CAMPAIGN_END_DATE               = new Date("Feb 04 2014 16:00:00 GMT")
  OLD_DISK_SIZE_IN_MB             = 250

  # this functions checks default vm and updates disk size
  # if required, when vm disk size is updated, returns hostname
  # why this is here, because it will be deleted after 100TB campaign ends
  @resetVMDefaults = secure (client, callback)->
    JVM.fetchDefaultVm_ client, (err, vm)->
      return callback err if err
      return callback new Error "VM not found" unless vm
      if vm.diskSizeInMB and vm.diskSizeInMB >= JVM.VMDefaultDiskSize
        return callback null, no
      else
        JVM.resetDefaultVMLimits client, (er, vmName)->
          return callback err if err
          return callback null, yes, vmName

  @isCampaingValid = isCampaingValid = (callback)->
    fetchTBCampaign (err, campaign)->
      return callback err if err
      return callback null, no unless campaign
      {diskSpaceLeftMB, endDate} = campaign.content
      # if campaign has more disk space
      if diskSpaceLeftMB > 0
        # if campaign is valid
        if endDate.getTime() > +(new Date())
          return callback null, yes, campaign
        else
          return callback null, no

      # this is an edge case, if campaing has negative
      # disk size set it back to 0
      else
        return callback null, no
        # do not allow negative numbers
        JStorage.update
          name: CAMPAIGN_NAME
        , $set : "content.diskSpaceLeftMB" : 0
        , ->

  getReferralDiskSizeAmount=(callback)->
    isCampaingValid (err, status)->
      return callback null, OLD_DISK_SIZE_IN_MB if err or not status
      return callback null, CAMPAIGN_DISK_SIZE_IN_MB

  decreaseLeftSpace = (size, callback = ->)->
    isCampaingValid (err, status)->
      return callback err if err
      return callback null unless status

      # change value with negative
      size = -size if size > 0
      JStorage = require '../storage'
      JStorage.update
        name: CAMPAIGN_NAME
      , $inc : "content.diskSpaceLeftMB" : size
      , callback


  decreaseLeftSpaceInTimeout = (options, callback = ->)->
    oneDayInMs = 86400000
    sevenDayInMs = oneDayInMs*7
    totalTimeInMs = sevenDayInMs

    totalMBPerMS = CAMPAIGN_TOTAL_DISK_SIZE_IN_MB/totalTimeInMs
    socialServerCount = 2
    totalMBPerMSPerSocialWorker = totalMBPerMS/KONFIG.social.numberOfWorkers/socialServerCount
    cachingTimeInMS = 10000

    toBeDecreasedSize= parseInt(totalMBPerMSPerSocialWorker*cachingTimeInMS, 10)
    decreaseLeftSpace toBeDecreasedSize
    callback null, {}

  @fetchTBCampaign = fetchTBCampaign= (callback)->

    Cache  = require '../../cache/main'
    cacheKey = "fetchTBCampaign"

    Cache.fetch cacheKey, decreaseLeftSpaceInTimeout, {}, ->

    JStorage = require '../storage'
    JStorage.one {name: CAMPAIGN_NAME}, (err, campaign) ->
      return callback err if err
      unless campaign
        cmp = new JStorage
          name: CAMPAIGN_NAME
          content:
            diskSpaceLeftMB : CAMPAIGN_TOTAL_DISK_SIZE_IN_MB
            endDate         : CAMPAIGN_END_DATE
            startDate       : CAMPAIGN_START_DATE

        cmp.save (err)->
          return callback err if err
          return callback null, cmp
      else
        return callback null, campaign

  do =>
    JAccount.on 'AccountRegistered', (me, referrerCode)->
      return console.error "Account is not defined in event" unless me
      return console.log "User dont have any referrer" unless referrerCode
      if me.profile.nickname is referrerCode
          return console.error "#{me.profile.nickname} - User tried to refer themself"

      me.update { $set : 'referrerUsername' :  referrerCode }, (err)->
        return console.error err if err
        console.log "referal saved successfully for #{me.profile.nickname} from #{referrerCode}"

    persistReferrals = (source, target, callback)->
      getReferralDiskSizeAmount (err, amount)->
        return callback err if err
        referral = new JReferral { type: "disk", unit: "MB", amount}
        referral.save (err) ->
          return callback err if err
          #add referrer as referrer to the referral system
          source.addReferrer referral, (err)->
            return callback err if err
            # add me as referred to the referral system
            target.addReferred referral, (err)->
              return callback err if err
              console.info "referal saved successfully for #{target.profile.nickname} from #{source.profile.nickname}"
              callback null

              # do this async
              decreaseLeftSpace amount, (err)->
                return console.error err if err

    JUser.on 'EmailConfirmed', (user)->
      return console.log "User is not defined in event" unless user
      isCampaingValid (err, status)->
        return if err or not status
        user.fetchOwnAccount (err, me)->
          return console.error err if err
          # if account not fonud then do nothing and return
          return console.error "Account couldnt found" unless me
          referrerUsername = me.referrerUsername
          return console.info "User doesn't have any referrer" unless referrerUsername
          # get referrer
          JAccount.one {'profile.nickname': referrerUsername }, (err, referrer)->
            # if error occured than do nothing and return
            return console.error "Error while fetching referrer", err if err
            # if referrer not fonud then do nothing and return
            return console.error "Referrer couldnt found" if not referrer
            persistReferrals referrer, me, (err)->
              return console.error err if err
              persistReferrals me, referrer, (err)->
                return console.error err if err
