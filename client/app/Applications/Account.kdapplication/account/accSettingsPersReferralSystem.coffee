class AccountReferralSystemListController extends AccountListViewController

  constructor: (options, data)->
    options.noItemFoundText = "You dont have any referal."
    super options, data

  loadItems: ->
    @removeAllItems()
    @showLazyLoader yes
    KD.remote.api.JReferral.fetchReferredAccounts (err, referals)=>
      return KD.showError err if err
      @instantiateListItems referals or []
    @hideLazyLoader()

    @on "RedeemReferralPointSubmitted", @bound "redeemReferralPoint"
    @on "ShowRedeemReferralPointModal", @bound "showRedeemReferralPointModal"

  notify_:(message)->
    new KDNotificationView
      title    : message
      duration : 2500

  redeemReferralPoint:(modal)->
    {vmToResize, sizes} = modal.modal.modalTabs.forms.Redeem.inputs
    data = { vm : vmToResize.getValue(), size : sizes.getValue() }
    KD.remote.api.JReferral.redeem data, (err, refRes)=>
      return KD.showError err if err
      modal.modal.destroy()
      KD.getSingleton("vmController").resizeDisk data.vm, (err, res)=>
        return KD.showError err if err
        @notify_ """
          #{refRes.addedSize} MB extra disk space is successfully added to your #{refRes.vm} VM. Your new disk space is #{refRes.newDiskSpace}
        """


  showRedeemReferralPointModal:()->
    KD.remote.api.JReferral.fetchRedeemableReferrals (err, referals)=>
      return KD.showError err if err
      return @notify_ "You dont have any referrals" if not referals or referals.length < 1

      @modal = modal = new KDModalViewWithForms
        title                   : "Redeem Your Referral Points"
        content                 : ""
        overlay                 : yes
        width                   : 500
        height                  : "auto"
        tabs                    :
          forms                 :
            Redeem               :
              callback          : =>
                @modal.modalTabs.forms.Redeem.buttons.redeemButton.showLoader()
                @emit "RedeemReferralPointSubmitted", @
              buttons           :
                redeemButton    :
                  title         : "Redeem"
                  style         : "modal-clean-gray"
                  type          : "submit"
                  loader        :
                    color       : "#444444"
                    diameter    : 12
                  callback      : -> @hideLoader()
                cancel          :
                  title         : "Cancel"
                  style         : "modal-cancel"
                  callback      : (event)-> modal.destroy()
              fields            :
                vmToResize    :
                  label         : "Select a WM to resize"
                  itemClass     : KDSelectBox
                  type          : "select"
                  name          : "vmToResize"
                  selectOptions : (cb)->
                    vmController = KD.getSingleton("vmController")
                    vmController.fetchVMs yes, (err, vms)=>
                      return KD.showError err if err
                      options = for vm in vms
                        ( title : vm, value : vm)
                      cb options

                sizes           :
                  label         : "Select Size"
                  itemClass     : KDSelectBox
                  type          : "select"
                  name          : "size"
                  validate      :
                    rules       :
                      required  : yes
                    messages    :
                      required  : "You must select a size!"
                  selectOptions : (cb)=>
                    options = []
                    previousTotal = 0
                    referals.forEach (referal, i)->
                      previousTotal += referal.earnedDiskSpaceInMB
                      options.push ( title : "#{previousTotal} MB" , value : previousTotal)
                    cb options


  loadView: ->
    super
    @loadItems()

    @getView().parent.addSubView getYourRefererCode = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Get Your Referer Code"
      cssClass     : "action-link"
      attributes   :
        href       : "#"
      click     : =>
        KD.whoami().createReferrerCode (err, refererCode)=>
          return notify_ err.message if err
          shareUrl      = "#{location.origin}/?r=#{refererCode}"
          getYourRefererCode._shorten = shareUrl

          contextMenu   = new JContextMenu
            cssClass    : "activity-share-popup"
            type        : "activity-share"
            delegate    : getYourRefererCode
            x           : getYourRefererCode.getX() - 35
            y           : getYourRefererCode.getY() - 50
            arrow       :
              placement : "bottom"
              margin    : 110
            lazyLoad    : yes
          , customView  : new SharePopup {
              url     : shareUrl
              twitter :
                text    : "Join to Koding! The next generation develepment environment koding.com"
            }
          new KDOverlayView
            parent      : KD.singletons.mainView.mainTabView.activePane
            transparent : yes


    @getView().parent.addSubView redeem = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Redeem Your Referer Points"
      cssClass     : "action-link"
      attributes   :
        href       : "#"
      click     : =>
        @emit "ShowRedeemReferralPointModal", @


class AccountReferralSystemList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountReferralSystemListItem
    ,options
    super options,data


class AccountReferralSystemListItem extends KDListItemView
  constructor: (options, data)->
    options =
      tagName: "li"
    super options, data

  viewAppended: ->
    super

  partial: (data)->
    """
    <a href="/#{data.profile.nickname}"> #{data.profile.firstName} #{data.profile.lastName} </a>
    """
