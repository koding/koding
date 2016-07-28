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

    logo = team.customize?.logo ? ''
    @logoWrapper = new kd.CustomHTMLView
      cssClass : 'team-logo-wrapper'
    @logoWrapper.addSubView new kd.CustomHTMLView
      tagName    : 'img'
      attributes :
        src      : "#{logo}"

    { groupsController } = kd.singletons
    currentGroup = groupsController.getCurrentGroup()

    if currentGroup.slug is slug
      @actionElement = new kd.CustomHTMLView
        tagName  : 'span'
        cssClass : 'active-team-label'
        partial  : 'Active Team <div class="circle"></div>'
      return

    { protocol } = document.location
    hostname     = globals.config.domains.main
    domain       = if slug is 'koding' then hostname else "#{slug}.#{hostname}"

    @actionElement = new kd.CustomHTMLView
      tagName    : 'a'
      partial    : 'Switch'
      cssClass   : 'GenericButton'
      attributes :
        href     : "#{protocol}//#{domain}"
        target   : '_self'


  pistachio: ->

    { title } = @getData()

    """
      <div class="team-title-wrapper">
        {{> @logoWrapper}}
        <span class="team-title">#{title}</span>
      </div>
      {{> @actionElement }}
    """
