kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDNotificationView = kd.NotificationView
AccountListViewController = require '../controllers/accountlistviewcontroller'
remote = require('app/remote').getInstance()
showError = require 'app/util/showError'


module.exports = class AccountReferralSystemListController extends AccountListViewController

  constructor: (options, data)->
    options.noItemFoundText = ""# """You haven't got any referral points to claim,
      # click <a href="/Account/Referrer">here</a> to share Koding and get some!
    # """

    super options, data

  loadItems: ->
    @removeAllItems()
    @showLazyLoader yes
    query = { type : "disk" }
    options = {limit : 20}
    remote.api.JReferral.fetchReferredAccounts query, options, (err, referals)=>
      return showError err if err
      @instantiateListItems referals or []
    @hideLazyLoader()

  loadView: ->
    super
    @addHeader()
    @loadItems()

  # showRedeemReferralPointModal:->
  #   KD.mixpanel "Referer Redeem Point modal, click"

  #   appManager = KD.getSingleton "appManager"
  #   appManager.tell "Account", "showRedeemReferralPointModal"


  addHeader:->

    wrapper = new KDCustomHTMLView tagName : 'header', cssClass : 'clearfix'
    @getView().addSubView wrapper, '', yes

    # wrapper.addSubView getYourReferrerCode = new CustomLinkView
    #   title       : "Get Your Referral Code"
    #   tooltip     :
    #     title     :
    #       """
    #       Only this week, share your link, they get 5GB instead
    #       of 4GB, and you get 1GB extra!
    #       """
    #   click       : ->
    #     appManager = KD.getSingleton "appManager"
    #     appManager.tell "Account", "showReferrerModal",
    #       linkView    : getYourReferrerCode

    wrapper.addSubView redeem = new KDButtonView
        cssClass  : 'add-big-btn'
        title     : 'Redeem your VM space'
        icon      : yes
        callback  : =>
          new KDNotificationView title: "Coming soon!"
          # @showRedeemReferralPointModal()

