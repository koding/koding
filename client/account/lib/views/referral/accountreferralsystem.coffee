kd                  = require 'kd'
remote              = require('app/remote').getInstance()
showError           = require 'app/util/showError'
ReferralCustomViews = require './referralcustomviews'


module.exports      = class AccountReferralSystem extends kd.View

  ReferralCustomViews.mixin @prototype

  viewAppended: ->

    limit  = 5
    loader = @addTo this, loader: 'initial-loader'

    @fetcher {limit}, (err, data) =>

      loader.destroy()

      return  if not data or showError err

      {rewards, average, total} = data

      average ?= 6
      total   /= 1000
      maxGiven = Math.max total, average

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
            max            : maxGiven
            current        : average
            color          : if average > total then 'green' else 'yellow'
          progress_you     :
            title          : 'You'
            max            : maxGiven
            current        : total
            color          : if total > average then 'green' else 'yellow'
          list             : {data: rewards, @fetcher, limit}


  fetcher: (options = {}, callback) ->
    query         = type: 'disk'
    options.sort ?= createdAt : -1
    remote.api.JReward.fetchCustomData query, options, callback
