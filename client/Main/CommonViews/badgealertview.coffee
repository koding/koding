class BadgeAlertView extends KDView
  constructor:(options = {}, data)->
    # TODO : need styling! That's dummy notification

    {countOptions} = options
    client = KD.whoami()
    client.updateCountAndCheckBadge countOptions,(badges)->
      if badges
        for badge in badges
          new KDNotificationView
            title    : "Congratz dude you got the " + badge.title + " badge!"
            subtitle : badge.description
            content  : "<img src='" + badge.iconURL + "'/>"
            type     : "growl"
            duration : 2000
    super options, data