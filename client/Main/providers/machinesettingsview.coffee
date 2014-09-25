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
          label         : "Access URI"
          itemClass     : CustomLinkView
          title         : accessUri
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
        publicIp        :
          label         : "Public IP"
          cssClass      : if running then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : data.ipAddress or "N/A"
        specs           :
          label         : "Specs"
          itemClass     : KDView
          partial       : "1GB Ram, 1Core, #{storage}GB Disk"
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

      @machine.setLabel label, (err, newSlug)=>

        if not KD.showError err

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

    {moreView, nickname, nickEdit} = @modalTabs.forms.Settings.inputs

    moreLabel = moreView.getOption 'label'
    moreLabel.on 'click', =>
      moreLabel.toggleClass 'expanded'
      @moreForm.toggleClass 'hidden'

    {windowController, computeController} = KD.singletons

    nickname.on 'click', =>
      nickname.hide()

      windowController.addLayer nickEdit
      nickEdit.once "ReceivedClickElsewhere", ->
        nickEdit.hide()
        nickname.show()

      nickEdit.setValue @machine.label
      nickEdit.show()

      KD.utils.defer -> nickEdit.setFocus()


    @addSubView @moreForm = new KDFormViewWithFields
      cssClass         : 'more-form hidden'
      fields           :
        alwaysOn       :
          label        : "Keep VM always on"
          itemClass    : KodingSwitch
          defaultValue : @machine.alwaysOn
          cssClass     : "tiny"
          callback     : (state) => @emit 'AlwaysOnStateChange', state
        advancedView   :
          label        : "Advanced"
          itemClass    : KDCustomHTMLView

    {advancedView} = @moreForm.inputs
    {label}        = advancedView.getOptions()

    label.on 'click', =>
      label.toggleClass 'expanded'
      @buttonContainer.toggleClass 'hidden'

    @addSubView @buttonContainer = new KDView
      cssClass : 'button-container hidden'

    @buttonContainer.addSubView @reinitButton = new KDButtonView
      style    : 'solid compact red reinit'
      title    : 'Reinitialize VM'
      callback : =>
        computeController.reinit @machine
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
