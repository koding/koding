JView          = require './../core/jview'
CustomLinkView = require './../core/customlinkview'

module.exports = class AboutListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options={}, data)->

    options.tagName = 'li'
    options.type    = 'team'

    super options, data

    {username} = @getData()
    @avatar    = new KDCustomHTMLView
      tagName  : 'img'
      cssClass : 'avatarview'
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

