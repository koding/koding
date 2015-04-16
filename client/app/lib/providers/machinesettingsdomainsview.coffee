kd                        = require 'kd'
nick                      = require 'app/util/nick'
KDView                    = kd.View
globals                   = require 'globals'
Machine                   = require 'app/providers/machine'
htmlencode                = require 'htmlencode'
DomainItem                = require 'app/domains/domainitem'
KDModalView               = kd.ModalView
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
      .on 'DomainStateChanged',    @bound 'handleStateChange'


  createElements: ->

    @createHeader()
    @createListView()
    @createAddView()


  createAddInput: ->

    super

    @domainSuffix = ".#{nick()}.#{globals.config.userSitesDomain}"

    @addViewContainer.addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'domain-suffix'
      partial  : @domainSuffix

    kd.utils.defer @addInputView.bound 'setFocus'


  initList: ->

    return no  if @getData().status.state isnt Machine.State.Running

    kd.singletons.computeController.fetchDomains (err, domains = []) =>
      kd.warn err  if err

      @listController.lazyLoader.hide()
      @listController.replaceAllItems domains


  showAddView: ->

    if @listController.getItemCount() >= 5
      warning = 'The new domain cannot be created as you have already reached the allowed limit of 5 domains.'
      @showNotification warning, 'warning'
      return @addNewButton.hideLoader()

    super


  hideAddView: ->

    return no  if @isInProgress

    super


  handleAddNew: ->

    domainName = @addInputView.getValue().trim()
    machineId  = @machine._id
    { computeController } = kd.singletons

    return no  if @isInProgress
    return @addNewButton.hideLoader()  if domainName is ''

    domain = "#{htmlencode.XSSEncode domainName}#{@domainSuffix}"

    @isInProgress = yes
    @addInputView.makeDisabled()
    @addNewButton.showLoader()

    @notificationView.hide()

    computeController.getKloud()

      .addDomain { domainName: domain, machineId }

      .then =>
        @listController.addItem { domain, machineId }
        # we are doing this to reset domain list in memory of computecontroller
        computeController.domains = []

        @isInProgress = no
        @addInputView.setValue ''
        @hideAddView()

      .catch (err) =>
        @showNotification err
        @addInputView.makeEnabled()
        @addInputView.setFocus()
        @addNewButton.hideLoader()

      .finally =>
        @isInProgress = no
        @addInputView.makeEnabled()
        @addNewButton.hideLoader()


  removeDomain: (domainItem) ->

    { computeController } = kd.singletons

    { domain }  = domainItem.getData()
    machineId   = @machine._id

    @notificationView.hide()
    domainItem.setLoadingMode yes

    computeController.getKloud()

      .removeDomain { domainName: domain, machineId }

      .then =>
        @listController.removeItem domainItem
        computeController.domains = []

      .catch (err) =>
        domainItem.setLoadingMode no
        @showNotification err


  handleStateChange: (domainItem, state) ->

    domainItem.setLoadingMode yes

    @notificationView.hide()

    @askForPermission domainItem, state, (approved) =>
      if approved
        @changeDomainState domainItem, state
      else
        @revertToggle domainItem, state
        domainItem.setLoadingMode no


  changeDomainState: (domainItem, state) ->

    { computeController } = kd.singletons
    { stateToggle }       = domainItem
    { domain }            = domainItem.getData()
    machineId             = @machine._id
    action                = if state then 'setDomain' else 'unsetDomain'

    computeController.getKloud()[action] { domainName: domain, machineId }
      .then ->
        computeController.domains = []
        domainItem.data.machineId = null  unless state

      .catch (err) =>
        @showNotification err

        @revertToggle domainItem, state
        domainItem.setLoadingMode no

      .finally =>
        domainItem.setLoadingMode no


  revertToggle: (domainItem, state) ->

    { stateToggle } = domainItem
    if state then stateToggle.setOff no else stateToggle.setOn no


  askForPermission: (domainItem, state, callback) ->

    { domain, machineId } = domainItem.getData()

    return callback yes  if not state or not machineId

    { computeController } = kd.singletons

    modal = new KDModalView
      cssClass      : 'domain-assign-modal'
      title         : 'Reassign domain ?'
      content       : """
        <div class='modalformline'>
          <p>
            The domain that you are trying to add: <b>#{domain}</b> is already
            assigned to another VM that you own. If you continue, this domain
            will be reassigned to the current VM and disassociated with all others.
          </p>
          <p></p>
          <p>Continue?</p>
        </div>
      """
      overlay       : yes
      cancel        : ->
        modal.destroy()
        callback no
      buttons       :
        OK          :
          title     : 'Yes'
          style     : 'solid red medium'
          loader    :
            color   : 'darkred'
          callback  : ->
            modal.destroy()
            callback yes
        cancel      :
          title     : 'Cancel'
          style     : 'solid light-gray medium'
          callback  : -> modal.cancel()
