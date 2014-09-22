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
      computeController.setAlwaysOn @machine, state, (err)->
        if KD.showError err then alwaysOn.setOff no

    @on 'UpdateNickname', =>

      {nickEdit, nickname} = @modalTabs.forms.Settings.inputs
      label = nickEdit.getValue()

      @machine.setLabel label, (err, newSlug)=>

        if not KD.showError err

          nickname.updatePartial "#{label}<cite></cite>"

          nickEdit.hide()
          nickname.show()



  viewAppended:->

    {moreView, nickname, nickEdit} = @modalTabs.forms.Settings.inputs

    moreLabel = moreView.getOption 'label'
    moreLabel.on 'click', =>
      moreLabel.toggleClass 'expanded'
      @moreForm.toggleClass 'hidden'

    windowController = KD.getSingleton "windowController"

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
      @terminateButton.toggleClass 'hidden'

    @addSubView @terminateButton = new KDButtonView
      style    : 'solid compact red hidden'
      title    : 'Terminate VM'
      callback : =>
        KD.singletons.computeController.destroy @machine
        @destroy()

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 20
