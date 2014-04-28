class AboutListItem extends KDListItemView

  constructor:(options={}, data)->

    options.tagName = 'li'
    options.type    = 'team'

    super options, data

    {username} = @getData()
    @avatar    = new AvatarView
      origin   : username
      size     : width : 160

    @link      = new CustomLinkView
      cssClass : 'profile'
      href     : "/#{username}"
      title    : "@#{username}"

    @title     = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'title'
      partial  : @getData().title


  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <figure>
      {{> @avatar}}
    </figure>
    <figcaption>
      {{> @link}}
      {{> @title}}
    </figcaption>
    """

