class AvatarArea extends KDCustomHTMLView

  constructor: (options = {}, data)->

    options.cssClass or= 'avatar-area'

    super options, data

    account = @getData()

    @avatar = new AvatarView
      tagName    : "div"
      cssClass   : "avatar-image-wrapper"
      attributes :
        title    : "View your public profile"
      size       :
        width    : 36
        height   : 36
    , account

    @profileLink = new ProfileLinkView {}, account

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {{> @avatar}}
    <section>
      <h2>{{> @profileLink}}</h2>
      <h3>Designer</h3>
      <cite></cite>
    </section>
    """