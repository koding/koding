kd = require 'kd'
React = require 'react'
cdnize = require 'app/util/cdnize'
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'
globals = require 'globals'
TransferOwnershipButton = require 'home/myteam/components/transferownershipbutton'


module.exports = class SingleGroupInfo extends kd.CustomHTMLView

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry 'single-group-info', options.cssClass

    super options, data

    group = @getData()
    roles = group.roles

    selectOptions = null

    @addSubView teamlogowrapper = new kd.CustomHTMLView
      cssClass: 'teamlogo-wrapper'

    teamlogowrapper.addSubView teamlogo = new kd.CustomHTMLView
      cssClass: 'default'

    logoPath = cdnize group.customize?.logo

    if logoPath
      teamlogo.setClass 'team-logo'
      teamlogo.setPartial "<img src='#{logoPath}'/>"

    teamlogowrapper.addSubView teamname = new kd.CustomHTMLView
      cssClass: 'team-name'
      partial: capitalizeFirstLetter group.slug

    @addSubView buttonwrapper = new kd.CustomHTMLView
      cssClass: 'action-wrapper'

    buttonwrapper.addSubView ownershipBtn = new TransferOwnershipButton {}, group
    ownershipBtn.once 'KDObjectWillBeDestroyed', =>
      @destroy()

    buttonwrapper.addSubView deleteTeamButton = new kd.ButtonView
      title          : 'GO TO TEAM'
      cssClass       : 'GenericButton delete-team-button'
      callback       : ->

        hostname     = globals.config.domains.main
        domain       = if group.slug is 'koding' then hostname else "#{group.slug}.#{hostname}"
        actionLink = "//#{domain}/-/loginwithtoken?token=#{group.jwtToken}"
        window.open actionLink, '_blank'
