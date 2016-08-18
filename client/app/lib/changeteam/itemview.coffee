kd      = require 'kd'
JView   = require 'app/jview'
globals = require 'globals'

module.exports = class ChangeTeamListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'change-team-item', options.cssClass

    super options, data

    team = @getData()
    { customize, slug } = team

    @logoWrapper = new kd.CustomHTMLView
      cssClass : 'team-logo-wrapper'
    if logo = team.customize?.logo
      @logoWrapper.addSubView new kd.CustomHTMLView
        tagName    : 'img'
        attributes :
          src      : logo
    else
      @logoWrapper.addSubView new kd.CustomHTMLView
        cssClass   : 'default-team-logo'

    { groupsController } = kd.singletons
    currentGroup = groupsController.getCurrentGroup()

    if currentGroup.slug is slug
      @actionElement = new kd.CustomHTMLView
        tagName  : 'span'
        cssClass : 'current-team-label'
        partial  : 'Current Team'
      return

    hostname     = globals.config.domains.main
    domain       = if slug is 'koding' then hostname else "#{slug}.#{hostname}"

    hasInvitation  = team.invitationCode?
    actionTitle    = if hasInvitation then 'Join' else 'Switch'
    actionLink     = "//#{domain}"
    if hasInvitation
      actionLink   = "#{actionLink}/Invitation/#{encodeURIComponent team.invitationCode}"
    actionCssClass = "GenericButton #{if hasInvitation then 'join' else ''}"
    @actionElement = new kd.CustomHTMLView
      tagName    : 'a'
      partial    : actionTitle
      cssClass   : actionCssClass
      attributes :
        href     : actionLink
        target   : '_self'


  pistachio: ->

    """
      <div class="team-title-wrapper">
        {{> @logoWrapper}}
        {span.team-title{#(title)}}
      </div>
      {{> @actionElement }}
    """
