kd                        = require 'kd'
KDView                    = kd.View
remote                    = require('app/remote').getInstance()
showError                 = require 'app/util/showError'
KDButtonView              = kd.ButtonView
KDCustomHTMLView          = kd.CustomHTMLView
KDNotificationView        = kd.NotificationView
AccountReferralSystemList = require './accountreferralsystemlist'


module.exports = class AccountReferralSystem extends KDView

  constructor: (options = {}, data)->

    super options, data

  viewAppended: ->

    @addSubView new KDView partial: "Referral system will be here"
