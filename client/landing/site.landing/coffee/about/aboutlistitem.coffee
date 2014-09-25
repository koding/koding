JView          = require './../core/jview'
CustomLinkView = require './../core/customlinkview'

module.exports = class AboutListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options={}, data)->

    options.tagName = 'li'
    options.type    = 'team'

    super options, data

    {username, prefix} = @getData()
    dpr  = window.devicePixelRatio ? 1
    size = 160 * dpr
    hash = KD.utils.md5 "#{prefix or username}@koding.com"

    defaultAvatarUri = "https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png"
    src =  "//gravatar.com/avatar/#{hash}?size=#{size}&d=#{defaultAvatarUri}&r=g"

    @avatar    = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatarview'
      attributes : {src}
      size       : width : 160

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

