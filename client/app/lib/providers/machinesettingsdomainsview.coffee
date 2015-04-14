kd               = require 'kd'
nick             = require 'app/util/nick'
KDView           = kd.View
globals          = require 'globals'
KDCustomHTMLView = kd.CustomHTMLView

MachineSettingsCommonView = require './machinesettingscommonview'


module.exports = class MachineSettingsDomainsView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.header               = 'Domains'
    options.addButtonTitle       = 'ADD DOMAIN'
    options.headerAddButtonTitle = 'ADD NEW DOMAIN'

    super options, data


  createAddInput: ->

    super

    @domainSuffix = ".#{nick()}.#{globals.config.userSitesDomain}"

    @addViewContainer.addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'domain-suffix'
      partial  : @domainSuffix

    kd.utils.defer => @addInputView.setFocus()
