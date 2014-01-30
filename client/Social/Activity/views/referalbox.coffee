class ReferalBox extends JView


  constructor: (options = {}, data) ->

    options.cssClass = 'referal-box'

    super options, data

    @modalLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : @bound 'showReferrerModal'
      partial    : 'show more...'

    @redeemPointsModal = new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '#'
      click      : (e)=>
        @showRedeemReferralPointModal()
        e.stopPropagation()

    KD.getSingleton("vmController").on "ReferralCountUpdated", =>
      @updateReferralCountPartial()
      @updateSizeBar()

    @updateReferralCountPartial()

    @progressBar = new KDProgressBarView
      title       : '0 GB / 16 GB'
      determinate : yes

  click : -> @showReferrerModal()


  showRedeemReferralPointModal:->
    KD.mixpanel "Referer Redeem Point modal, click"

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showRedeemReferralPointModal"

  updateReferralCountPartial:->
    KD.remote.api.JReferral.fetchRedeemableReferrals { type: "disk" }, (err, referals)=>
      if referals and referals.length > 0
        text =  """
          Congrats, your bonus is waiting for you!
          You have #{referals.length} referrals!
        """
        @redeemPointsModal.updatePartial text


  viewAppended:->

    super
    @updateSizeBar()

  updateSizeBar:->
    @progressBar.updateBar 0
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) =>
      vmc.fetchVmInfo name, (err , vmInfo) =>
        return  if err or not vmInfo?.diskSizeInMB
        max          = vmInfo?.diskSizeInMB or 4096
        max          = max*1024*1024
        usagePercent = max / (16*1e9) * 90
        used         = KD.utils.formatBytesToHumanReadable max

        @progressBar.updateBar usagePercent + 10, null, "#{used} / 16 GB"


  showReferrerModal: (event)->
    KD.utils.stopDOMEvent event
    KD.mixpanel "Referer modal, click"

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerModal"

  pistachio:->
    """
    <strong>#Crazy100TBWeek</strong>
    <p>
    Only this week, share your link, they get 5GB instead of 4GB, and you get 1GB extra! {{> @modalLink}}
    {{> @redeemPointsModal}}
    </p>
    {{> @progressBar}}
    """

