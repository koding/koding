kd                        = require 'kd'
nick                      = require 'app/util/nick'
KDView                    = kd.View
globals                   = require 'globals'
DomainItem                = require 'app/domains/domainitem'
KDCustomHTMLView          = kd.CustomHTMLView
MachineSettingsCommonView = require './machinesettingscommonview'


module.exports = class MachineSettingsDomainsView extends MachineSettingsCommonView


  constructor: (options = {}, data) ->

    options.headerTitle          = 'Domains'
    options.addButtonTitle       = 'ADD DOMAIN'
    options.headerAddButtonTitle = 'ADD NEW DOMAIN'
    options.listViewItemClass    = DomainItem

    super options, data


  createAddInput: ->

    super

    @domainSuffix = ".#{nick()}.#{globals.config.userSitesDomain}"

    @addViewContainer.addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'domain-suffix'
      partial  : @domainSuffix

    kd.utils.defer => @addInputView.setFocus()


  initList: ->

   kd.singletons.computeController.fetchDomains (err, domains = []) =>
      kd.warn err  if err

      @listController.lazyLoader.hide()
      @listController.replaceAllItems domains

