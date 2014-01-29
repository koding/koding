class TBCampaignController extends KDController

  constructor: (options = {}, data) ->

    super options, data

    userAccount           = KD.whoami()
    campaignStartDateInMs = new Date(data.content.startDate).getTime()
    registerDateInMs      = new Date(userAccount.meta.createdAt).getTime()
    registrationDateDiff  = registerDateInMs - campaignStartDateInMs

    @appStorage = KD.getSingleton('appStorageController').storage 'Finder', '1.1.1'
    @appStorage.fetchStorage (storage) =>
      hasShownBefore = @appStorage.getValue "TBCampaignModalShown"
      return if hasShownBefore

      if registrationDateDiff > 0
        referrer = userAccount.referrerUsername
        if referrer
          @showModal { userType: "referral", referrer }
          KD.mixpanel "TBCampaign referral modal shown", { referrer, referral: KD.nick() }
        else
          @showModal { userType: "direct" }
          KD.mixpanel "TBCampaign direct user registered"
      else
        @checkExistingUserStatus()

  checkExistingUserStatus: ->
    KD.remote.api.JReferral.resetVMDefaults (err, hasUnder4GB, targetVMName) =>
      return warn err  if err

      if hasUnder4GB
        KD.getSingleton("vmController").resizeDisk targetVMName, (err, res) =>
          return warn err  if err
          @showModal { userType: "under4GB" }
          KD.mixpanel "TBCampaign old user disk upgraded to 4GB"
      else
        @showModal { userType: "above4GB" }
        KD.mixpanel "TBCampaign user has more than 4GB storage"

  showModal: (config) ->
    new TBCampaignModal config
    @appStorage.setValue "TBCampaignModalShown", yes
