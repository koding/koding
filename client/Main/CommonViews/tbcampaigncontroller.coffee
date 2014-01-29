class TBCampaignController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    campaignStartDateInMs = 1390951988757
    userAccount           = KD.whoami()
    registerDateInMs      = new Date(userAccount.meta.createdAt).getTime()
    registrationDateDiff  = registerDateInMs - campaignStartDateInMs

    @appStorage = KD.getSingleton('appStorageController').storage 'Finder', '1.1.1'
    @appStorage.fetchStorage (storage) =>
      hasShownBefore = @appStorage.getValue "TBCampaignModalShown"





      hasShownBefore = no







      return if hasShownBefore

      if registrationDateDiff > 0
        referrer = userAccount.referrerUsername
        if referrer
          @showModal { userType: "referral", referrer }
        else
          @showModal { userType: "direct" }
      else
        @checkExistingUserStatus()

  checkExistingUserStatus: ->
    KD.remote.api.JReferral.resetVMDefaults (err, hasUnder4GB, targetVMName) =>
      return warn err  if err

      if hasUnder4GB
        KD.getSingleton("vmController").resizeDisk targetVMName, (err, res) =>
          return warn err  if err
          @showModal { userType: "under4GB" }
      else
        @showModal { userType: "above4GB" }

  showModal: (config) ->
    new TBCampaignModal config
    @appStorage.setValue "TBCampaignModalShown", yes