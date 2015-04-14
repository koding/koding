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

    @listController.getListView()
      .on 'DeleteDomainRequested', @bound 'removeDomain'


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


  removeDomain: (domainItem) ->

    { computeController } = kd.singletons

    { domain }  = domainItem.getData()
    machineId   = @machine._id

    # @warning.hide()
    domainItem.setLoadingMode yes

    computeController.getKloud()

      .removeDomain { domainName: domain, machineId }

      .then =>
        @listController.removeItem domainItem
        computeController.domains = []

      .catch (err) =>
        kd.warn 'Failed to remove domain:', err
        domainItem.setLoadingMode no
        # @warning.setTooltip title: err.message
        # @warning.show()


