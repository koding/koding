class BadgeController extends KDController

  checkBadge: (options)->
    client = KD.whoami()
    client.updateCountAndCheckBadge options,(badges)->
        for badge in badges
          new KDNotificationView
            title    : "Congratz dude you got the " + badge.title + " badge!"
            subtitle : badge.description
            content  : "<img src='" + badge.iconURL + "'/>"
            type     : "growl"
            duration : 2000
