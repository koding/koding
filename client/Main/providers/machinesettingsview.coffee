class MachineSettingsPopup extends KDModalViewWithForms

  { Running, Starting } = Machine.State

  constructor:(options = {}, data = {})->

    running = data.status.state in [ Running, Starting ]
    storage = data.jMachine.meta.storage_size ? "0"
    accessUri = "http://#{data.domain}"
    { providers } = KD.config

    options             = KD.utils.extend options,
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
        publicIp        :
          label         : "Public IP"
          cssClass      : if running then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : data.ipAddress or "N/A"
        specs           :
          label         : "Specs"
          itemClass     : KDView
          partial       : "1GB RAM, 1Core, #{storage}GB Disk"
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

    { computeController } = KD.singletons

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
            KD.utils.defer => new ComputeErrorModal.Usage { plan }
          else
            KD.showError err
          alwaysOn.setOff no

    @on 'UpdateNickname', =>

      {nickEdit, nickname} = @modalTabs.forms.Settings.inputs
      label = nickEdit.getValue()

      {appManager, router} = KD.singletons

      if (KD.utils.slugify label) is ""
        return KD.showError "Nickname cannot be empty."

      @machine.setLabel label, (err, newSlug)=>

        return if KD.showError err

        nickname.updatePartial "#{label}<cite></cite>"

        nickEdit.hide()
        nickname.show()

        frontApp = appManager.getFrontApp()

        if frontApp.options.name is "IDE" and frontApp.workspaceData?

          return  unless @machine.slug is frontApp.workspaceData.machineLabel

          newRoute = "/IDE/#{newSlug}/#{frontApp.workspaceData.slug}"
          frontApp.workspaceData.machineLabel = newSlug

          KD.utils.defer ->
            computeController.once 'MachineDataUpdated', ->
              router.clear newRoute


  viewAppended:->

    {windowController, computeController} = KD.singletons

    {statusToggle, statusLoader} = @modalTabs.forms.Settings.inputs

    statusToggle.hide()

    machineId    = @machine._id
    currentState = @machine.status.state
    baseKite     = @machine.getBaseKite()

    computeController.getKloud()

      .info { machineId, currentState }
      .then (response)->

        if response.State is Running
        then statusToggle.setOn no
        else statusToggle.setOff no

        statusToggle.show()
        statusLoader.hide()

      .catch (err)->

        warn "Failed to fetch info for machine settings:", err
        statusLoader.hide()
        statusToggle.setOff no
        statusToggle.show()


    {moreView, nickname, nickEdit} = @modalTabs.forms.Settings.inputs

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

      KD.utils.defer -> nickEdit.setFocus()

    topDomain = "#{KD.nick()}.#{KD.config.userSitesDomain}"

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

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 20

    computeController.fetchUserPlan (plan)=>

      if plan in ['free', 'hobbyist']
        @terminateButton.hide()

        if plan is 'hobbyist' and @machine.jMachine.meta?.storage_size isnt 10
          @resizeButton.show()


  shareMachineWithUser: (username) ->
    @machine.jMachine.shareWith target: username
    @machine.getBaseKite().klientShare { username }
