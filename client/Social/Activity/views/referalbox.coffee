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

    @progressBar = new KDProgressBarView
      title       : '0 GB / 16 GB'
      determinate : yes

  click : -> @showReferrerModal()


  viewAppended:->

    super

    @progressBar.updateBar 0
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) =>
      vmc.fetchDiskUsage name, (usage) =>
        return  unless usage.max

        usagePercent = usage.max / (16*1e9) * 90
        used         = KD.utils.formatBytesToHumanReadable usage.max

        @progressBar.updateBar usagePercent + 10, null, "#{used} / 16 GB"


  showReferrerModal: (event)->
    KD.utils.stopDOMEvent event
    KD.mixpanel "Referer modal, click"

    appManager = KD.getSingleton "appManager"
    appManager.tell "Account", "showReferrerModal",
      # linkView    : getYourReferrerCode
      top         : 50
      left        : 35
      arrowMargin : 110


  pistachio:->
    """
    <figure></figure>
    <p>
    Invite your friends and get up to <strong>16GB</strong> for free! {{> @modalLink}}
    </p>
    {{> @progressBar}}
    """
