$ = require 'jquery'
globals = require 'globals'
showError = require '../util/showError'
nick = require '../util/nick'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields
KDHitEnterInputView = kd.HitEnterInputView
KDLoaderView = kd.LoaderView
KDModalViewWithForms = kd.ModalViewWithForms
KDProgressBarView = kd.ProgressBarView
KDView = kd.View
CustomLinkView = require '../customlinkview'
GuidesLinksView = require '../guideslinksview'
KodingSwitch = require '../commonviews/kodingswitch'
Machine = require './machine'
ManageDomainsView = require '../domains/managedomainsview'
Usage = require './usage'

module.exports = class MachineSettingsPopup extends KDModalViewWithForms

  { Running, Starting } = Machine.State

  constructor:(options = {}, data = {})->

    running = data.status.state in [ Running, Starting ]
    storage = data.jMachine.meta.storage_size ? "0"
    accessUri = "http://#{data.domain}"
    { providers } = globals.config

    options             = kd.utils.extend options,
      title             : "Configure Your VM"
      cssClass          : 'activity-modal vm-settings'
      content           : ""
      overlay           : yes
      width             : 335
      height            : 'auto'
      arrowTop          : no
      tabs              : forms: Settings: fields:
        accessUri       :
          label         : "Assigned URL"
          itemClass     : CustomLinkView
          cssClass      : 'assigned-url'
          title         : data.domain
          href          : accessUri
          target        : '_blank'
          tooltip       :
            title       : accessUri
            placement   : 'top'
        nickname        :
          label         : "Nickname"
          cssClass      : "custom-link-view"
          itemClass     : KDView
          partial       : "#{data.label}<cite></cite>"
          nextElement   :
            nickEdit    :
              itemClass : KDHitEnterInputView
              type      : 'text'
              cssClass  : 'hidden'
              attributes: spellcheck: false
              callback  : => @emit 'UpdateNickname'
        statusToggle    :
          label         : "On/Off"
          defaultValue  : running
          itemClass     : KodingSwitch
          cssClass      : "tiny"
          callback      : (state) => @emit 'StateChange', state
          nextElement   :
            statusLoader:
              itemClass : KDLoaderView
              cssClass  : 'in-progress'
              size      :
                width   : 14
                height  : 14
              loaderOptions :
                color   : '#333333'
              showLoader: yes
        diskUsage       :
          label         : 'Disk Usage'
          itemClass     : KDProgressBarView
          cssClass      : if running then 'disk-usage' else 'hidden'
          nextElement   :
            resizeIcon  :
              itemClass : KDCustomHTMLView
              cssClass  : 'resize-icon'
              tooltip   : title: 'Add more space', placement: top
        publicIp        :
          label         : "Public IP"
          cssClass      : if running then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : data.ipAddress or "N/A"
        specs           :
          label         : "Specs"
          itemClass     : KDView
          partial       : "1GB RAM, 1Core CPU, #{storage}GB Disk"
        provider        :
          label         : "Provider"
          itemClass     : CustomLinkView
          title         : providers[data.provider]?.name or "Custom"
          href          : providers[data.provider]?.link or "/"
          target        : '_blank'
        guides          :
          label         : "Guides"
          itemClass     : GuidesLinksView
        moreView        :
          label         : "More"
          itemClass     : KDCustomHTMLView

    super options, data

    { computeController } = kd.singletons

    @machine = @getData()

    @on 'StateChange', (state)=>
      if state then computeController.start @machine
      else computeController.stop @machine
      @destroy()

    @on 'AlwaysOnStateChange', (state)=>
      {alwaysOn} = @moreForm.inputs

      computeController.fetchUserPlan (plan)=>

        computeController.setAlwaysOn data, state, (err)=>
          return  unless err?
          if err.name is "UsageLimitReached" and plan isnt 'hobbyist'
            @destroy()
            kd.utils.defer => new Usage { plan }
          else
            showError err
          alwaysOn.setOff no

    @on 'UpdateNickname', =>

      {nickEdit, nickname} = @modalTabs.forms.Settings.inputs
      label = nickEdit.getValue()

      {appManager, router} = kd.singletons

      if (kd.utils.slugify label) is ""
        return showError "Nickname cannot be empty."

      @machine.setLabel label, (err, newSlug)=>

        return if showError err

        nickname.updatePartial "#{label}<cite></cite>"

        nickEdit.hide()
        nickname.show()

        frontApp = appManager.getFrontApp()

        if frontApp.options.name is "IDE" and frontApp.workspaceData?

          return  unless @machine.slug is frontApp.workspaceData.machineLabel

          newRoute = "/IDE/#{newSlug}/#{frontApp.workspaceData.slug}"
          frontApp.workspaceData.machineLabel = newSlug

          kd.utils.defer ->
            computeController.once 'MachineDataUpdated', ->
              router.clear newRoute


  viewAppended:->

    {windowController, computeController} = kd.singletons

    {statusToggle, statusLoader, diskUsage} = @modalTabs.forms.Settings.inputs

    statusToggle.hide()

    machineId    = @machine._id
    currentState = @machine.status.state
    baseKite     = @machine.getBaseKite()

    # To cache it before user request
    @fetchUsageInfo()

    computeController.getKloud()

      .info { machineId, currentState }
      .then (response)->

        if response.State is Running
        then statusToggle.setOn no
        else statusToggle.setOff no

        statusToggle.show()
        statusLoader.hide()

      .catch (err)->

        kd.warn "Failed to fetch info for machine settings:", err
        statusLoader.hide()
        statusToggle.setOff no
        statusToggle.show()

    diskUsage.updateBar 0, '%', 'checking usage...'

    baseKite.systemInfo()

      .then (info)->

        format = kd.utils.formatBytesToHumanReadable

        total  = info.diskTotal * 1024
        usage  = info.diskUsage * 1024
        free   = total - usage

        kd.utils.wait 200, ->
          diskUsage.updateBar \
            (info.diskUsage / info.diskTotal) * 100, '%', format usage

          diskUsage.setTooltip
            title: "#{format total} total and #{format free} free"

      .catch (err)->

        kd.warn "Failed to fetch system info for machine settings:", err
        diskUsage.updateBar 0, '%', 'failed to fetch usage!'


    {moreView, nickname,
     nickEdit, resizeIcon} = @modalTabs.forms.Settings.inputs

    resizeIcon.once 'click', =>

      @fetchUsageInfo (err, info)=>

        if showError err
          return @destroy()

        { plan, plans, usage, reward } = info

        limits  = plans[plan]
        options = { plan, limits, usage, reward, @machine }

        new (require './computeresizemodal') options

        @destroy()


    moreLabel = moreView.getOption 'label'
    moreLabel.on 'click', =>
      moreLabel.toggleClass 'expanded'
      @moreForm.toggleClass 'hidden'

    nickname.on 'click', =>
      nickname.hide()

      windowController.addLayer nickEdit
      nickEdit.once "ReceivedClickElsewhere", ->
        nickEdit.hide()
        nickname.show()

      nickEdit.setValue @machine.label
      nickEdit.show()

      kd.utils.defer -> nickEdit.setFocus()

    topDomain = "#{nick()}.#{globals.config.userSitesDomain}"

    @addSubView @moreForm = new KDFormViewWithFields
      cssClass         : 'more-form hidden'
      fields           :
        alwaysOn       :
          label        : "Keep VM always on"
          itemClass    : KodingSwitch
          defaultValue : @machine.alwaysOn
          cssClass     : 'tiny'
          callback     : (state) => @emit 'AlwaysOnStateChange', state
        domains        :
          label        : "
            Domains
            <a href='http://learn.koding.com/faq/vm-hostname/' target='_blank'>
              <span class='domain-help'></span>
            </a>
            <span class='domain-toggle'></span>
          "
          itemClass    : ManageDomainsView
          machine      : @machine
        advancedView   :
          label        : "Advanced"
          itemClass    : KDCustomHTMLView

    {advancedView, domains} = @moreForm.inputs
    advancedLabel = advancedView.getOption 'label'

    advancedLabel.on 'click', =>
      advancedLabel.toggleClass 'expanded'
      @buttonContainer.toggleClass 'hidden'

    {label} = domains.getOptions()

    label.on 'click', (event)->
      return  unless $(event.target).hasClass 'domain-toggle'
      label.toggleClass 'expanded'
      domains.toggleInput()

    domains.on 'DomainInputCancelled', ->
      label.unsetClass 'expanded'

    @addSubView @buttonContainer = new KDView
      cssClass : 'button-container hidden'

    @buttonContainer.addSubView @reinitButton = new KDButtonView
      style    : 'solid compact red reinit'
      title    : 'Reinitialize VM'
      callback : =>
        computeController.reinit @machine
        @destroy()

    @buttonContainer.addSubView @resizeButton = new KDButtonView
      style    : 'solid compact green resize hidden'
      title    : 'Resize VM'
      callback : =>
        computeController.resize @machine, 10
        @destroy()

    @buttonContainer.addSubView @terminateButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Terminate VM'
      callback : =>
        computeController.destroy @machine
        @destroy()

    _addSubview = KDView::addSubView.bind this

    _addSubview new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 40

    computeController.fetchUserPlan (plan)=>

      if plan in ['free', 'hobbyist']
        @terminateButton.hide()

        if plan is 'hobbyist' and @machine.jMachine.meta?.storage_size isnt 10
          @resizeButton.show()


  shareMachineWithUser: (username) ->
    @machine.jMachine.shareWith target: username
    @machine.getBaseKite().klientShare { username }


  fetchUsageInfo: (callback = kd.noop)->

    return callback null, @fetchedInfo  if @fetchedInfo?

    kd.singletons.computeController.fetchPlanCombo 'koding', (err, info) =>
      if err then callback err
      else callback null, @fetchedInfo = info
