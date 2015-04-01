kd                        = require 'kd'
remote                    = require('app/remote').getInstance()
showError                 = require 'app/util/showError'
KDButtonView              = kd.ButtonView
KDCustomHTMLView          = kd.CustomHTMLView
KDNotificationView        = kd.NotificationView
AccountListViewController = require '../controllers/accountlistviewcontroller'


module.exports = class AccountReferralSystemListController extends AccountListViewController


  constructor: (options = {}, data)->
    options.noItemFoundText ?= "
      You haven't got any referral points to claim,
      click <a href='/Account/Referrer'>here</a> to share Koding and get some!
    "

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


  addHeader:->

    wrapper = new KDCustomHTMLView tagName : 'header', cssClass : 'clearfix'
    @getView().addSubView wrapper, '', yes
