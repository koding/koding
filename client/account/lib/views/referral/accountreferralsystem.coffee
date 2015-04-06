kd                  = require 'kd'
remote              = require('app/remote').getInstance()
timeago             = require 'timeago'
showError           = require 'app/util/showError'
ReferralCustomViews = require './referralcustomviews'


module.exports      = class AccountReferralSystem extends kd.View

  ReferralCustomViews.mixin @prototype

  buildViews: ({total, data})->

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
        list             : {data}


  viewAppended: ->

    loader = @addTo this, loader: 'initial-loader'
    @fetchData (err, {total, data})=>
      loader.destroy()
      unless showError err
        @buildViews {total, data}


  # TODO Move this to backend ~ GG
  fetchData: (callback)->

    {JReward} = remote.api
    JReward.fetchEarnedAmount type: 'disk', (err, total) =>
      return callback err  if err

      JReward.some {type: 'disk'}, {limit: 30}, (err, rewards) =>
        return callback err  if err

        data = []

        rewards.forEach (reward)->
          data.push
            friend       : reward.providedBy
            status       : 'claimed'
            lastActivity : timeago reward.createdAt
            spaceEarned  : reward.amount

        callback null, {total, data}
