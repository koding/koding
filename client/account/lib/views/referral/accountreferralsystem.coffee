kd                  = require 'kd'
ReferralCustomViews = require './referralcustomviews'


module.exports      = class AccountReferralSystem extends kd.View

  ReferralCustomViews.mixin @prototype

  viewAppended: ->

    average = 6
    total   = 1

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
        text             : "List referrals here"
