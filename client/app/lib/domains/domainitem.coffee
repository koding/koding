globals = require 'globals'
nick = require '../util/nick'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
CustomLinkView = require '../customlinkview'
KodingSwitch = require '../commonviews/kodingswitch'


module.exports = class DomainItem extends KDListItemView

  constructor:(options = {}, data)->

    options.type = 'domain'
    super options, data

  viewAppended: ->

    { domain, machineId } = @getData()
    currentMachineId      = @getOption 'machineId'

    topDomain  = "#{nick()}.#{globals.config.userSitesDomain}"

    @addSubView new CustomLinkView
      title    : domain
      href     : "http://#{domain}"
      target   : '_blank'

    unless domain is topDomain
      @addSubView new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'remove-domain'
        click    : =>
          @getDelegate().emit 'DeleteDomainRequested', this

    @addSubView @stateToggle = new KodingSwitch
      cssClass     : 'tiny'
      defaultValue : machineId is currentMachineId
      callback     : (state) =>
        @getDelegate().emit 'DomainStateChanged', this, state


