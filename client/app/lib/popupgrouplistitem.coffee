stringToColor = require './util/stringToColor'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
CustomLinkView = require './customlinkview'
JView = require './jview'
defaultSlug = require './util/defaultSlug'


module.exports = class PopupGroupListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.tagName or= "li"
    options.type    or= "activity-ticker-item"
    super

    {group:{title, avatar, slug, customize}, roles, admin} = @getData()
    roleClasses = roles.map((role)-> "role-#{role}").join ' '
    @setClass "role #{roleClasses}"

    defaultLogo  = "https://koding.s3.amazonaws.com/grouplogo_.png"

    @groupLogo  = new KDCustomHTMLView
      tagName    : "figure"
      cssClass   : "avatararea-group-logo"

    @switchLink = new CustomLinkView
      title       : title
      cssClass    : "avatararea-group-name"
      href        : "/#{if slug is defaultSlug then '' else slug+'/'}Activity"
      target      : slug

    @adminLink = if admin
      new CustomLinkView
        title       : ''
        href        : "/#{if slug is defaultSlug then '' else slug+'/'}Dashboard"
        target      : slug
        cssClass    : 'admin-icon'
        iconOnly    : yes
        icon        :
          cssClass  : 'dashboard-page'
          placement : 'right'
          tooltip   :
            title   : "Opens admin dashboard in new browser window."
            delayIn : 300
    else new KDCustomHTMLView

  pistachio: ->
    {group} = @getData()
    {slug, customize} = group

    if customize?.logo
      @groupLogo.setCss 'background-image', "url(#{customize?.logo})"
    else
      @groupLogo.setCss 'background-color', stringToColor slug

    """
    {{> @groupLogo}}{{> @switchLink}}{{> @adminLink}}
    """
