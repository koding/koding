class UserBadgeView extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data
    {iconURL, description} = @getData()

    @badgeIcon  = new KDCustomHTMLView
      tagName     : 'img'
      size        :
          width   : 70
          height  : 70
      attributes  :
        src       : iconURL
        title     : description or ''

  viewAppended: JView::viewAppended
  pistachio:->
    """
      {{> @badgeIcon}}
    """