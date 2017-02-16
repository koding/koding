kd = require 'kd'
React = require 'react'
cdnize = require 'app/util/cdnize'
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
capitalizeFirstLetter = require 'app/util/capitalizefirstletter'
globals = require 'globals'
TransferOwnershipButton = require '../transferownershipbutton'


module.exports = class SingleGroupInfo extends kd.CustomHTMLView

  constructor: (options, data) ->

    options = _.assign {}, options,
      cssClass : 'single-group-info'

    super options, data

    group = data
    roles = data.roles

    selectOptions = null

    @addSubView teamlogo = new kd.CustomHTMLView
      cssClass: 'default'

    logoPath = cdnize group.customize?.logo

    if logoPath
      teamlogo.setClass 'team-logo'
      teamlogo.setPartial "<img src='#{logoPath}'/>"

    @addSubView teamname = new kd.CustomHTMLView
      cssClass: 'team-name'
      partial: capitalizeFirstLetter group.slug

    @addSubView selection = new kd.SelectBox
      cssClass: 'select-box hidden'
      selectOptions: selectOptions
      callback: ->
        if selection.getValue()
          transferOwnership.unsetClass 'inactive'

    @addSubView buttonwrapper = new kd.CustomHTMLView
      cssClass: 'action-wrapper'

    buttonwrapper.addSubView ownershipBtn = new TransferOwnershipButton {}, group
    ownershipBtn.once 'destroy', =>
      @destroy()

    buttonwrapper.addSubView deleteTeamButton = new kd.ButtonView
      title          : 'Delete'
      cssClass       : 'GenericButton delete-team-button'
      callback       : ->

        hostname     = globals.config.domains.main
        domain       = if group.slug is 'koding' then hostname else "#{group.slug}.#{hostname}"
        actionLink = "//#{domain}/-/loginwithtoken?token=#{group.jwtToken}"
        window.open actionLink, '_blank'
