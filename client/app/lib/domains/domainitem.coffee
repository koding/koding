kd               = require 'kd'
nick             = require '../util/nick'
globals          = require 'globals'
KodingSwitch     = require '../commonviews/kodingswitch'
KDListItemView   = kd.ListItemView
CustomLinkView   = require '../customlinkview'
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class DomainItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = 'domain'

    super options, data


  viewAppended: ->

    { domain, machineId } = @getData()
    currentMachineId      = @getOption 'machineId'

    topDomain = "#{nick()}.#{globals.config.userSitesDomain}"

    @addSubView new CustomLinkView
      title  : domain
      href   : "http://#{domain}"
      target : '_blank'

    unless domain is topDomain
      @addSubView new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'remove'
        click    : =>
          @getDelegate().emit 'DeleteDomainRequested', this

    @addSubView @stateToggle = new KodingSwitch
      cssClass     : 'tiny'
      defaultValue : machineId is currentMachineId
      callback     : (state) =>
        @getDelegate().emit 'DomainStateChanged', this, state
