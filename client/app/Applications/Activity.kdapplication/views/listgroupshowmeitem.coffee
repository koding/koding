class ListGroupShowMeItem extends CommonInnerNavigationListItem

  click: (event) =>

    if @getData().disabledForBeta
      new KDNotificationView
        title : "Coming Soon!"
        duration : 1000
      return no

