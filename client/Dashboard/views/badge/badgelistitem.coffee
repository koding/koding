class BadgeListItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.cssClass = "items"
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

    @editButton = new KDButtonView
      title       : "Modify"
      cssClass    : "edit-badge"
      style       : "solid"
      callback    : =>
        modal     = new BadgeUpdateForm {itemList: this}, badge : @getData()

  viewAppended: JView::viewAppended

  pistachio:->
    {title} = @getData()
    """
      #{title}
      {{> @badgeIcon}}
      {{> @editButton}}
    """