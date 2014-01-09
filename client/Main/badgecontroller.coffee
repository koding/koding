class BadgeController extends KDController

  checkBadge: (options)->
    client = KD.whoami()
    client.updateCountAndCheckBadge options,(err, badges)->
      warn err if err
      for badge in badges
        new KDNotificationView
          title    : "Congratz dude you got the " + badge.title + " badge!"
          subtitle : badge.description
          content  : "<img src='#{badge.iconURL}'/>"
          type     : "growl"
          duration : 2000
        # Send Mixpanel event.
        KD.mixpanel "Badge Gain, click", badge.title
