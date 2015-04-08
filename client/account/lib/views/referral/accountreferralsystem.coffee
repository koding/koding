kd                  = require 'kd'
remote              = require('app/remote').getInstance()
showError           = require 'app/util/showError'
ReferralCustomViews = require './referralcustomviews'


module.exports      = class AccountReferralSystem extends kd.View

  ReferralCustomViews.mixin @prototype

  buildViews: ({total, rewards})->

    average = 6
    total  /= 1000

    @addCustomViews
      container_top      :
        totalSpace       : total
        shareBox         :
          title          : "You can earn up to 20gb of free disk space
                            by sharing your referral link with your friends."
          subtitle       : "Share on social media and get more referrals."
      container_bottom   :
        progress_average :
          title          : 'Average space earned'
          max            : average
          current        : average
          color          : if average > total then 'green' else 'yellow'
        progress_you     :
          title          : 'You'
          max            : Math.max total, average
          current        : total
          color          : if total > average then 'green' else 'yellow'
        list             : data: rewards


  viewAppended: ->

    loader = @addTo this, loader: 'initial-loader'

    remote.api.JReward.fetchCustomData
      type  : 'disk'
    , limit : 30
    , (err, data) =>

      @buildViews data  unless showError err
      loader.destroy()
