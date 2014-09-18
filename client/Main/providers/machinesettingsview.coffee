class MachineSettingsPopup extends KDModalViewWithForms

  { Running, Starting } = Machine.State

  constructor:(options = {}, data = {})->

    running = data.status.state in [ Running, Starting ]
    storage = data.jMachine.meta.storage_size ? "0"

    options             = KD.utils.extend options,
      title             : 'Configure Your VM'
      cssClass          : 'activity-modal vm-settings'
      content           : ''
      overlay           : yes
      width             : 335
      height            : 'auto'
      arrowTop          : no
      tabs              : forms: Settings: fields:
        accessUri       :
          label         : "Access URI"
          itemClass     : CustomLinkView
          title         : "http://#{data.domain}"
          href          : "http://#{data.domain}"
          target        : "_blank"
        nickname        :
          label         : "Nickname"
          cssClass      : "custom-link-view"
          itemClass     : KDView
          partial       : data.label
        statusToggle    :
          label         : "On/Off"
          defaultValue  : running
          itemClass     : KodingSwitch
          cssClass      : "tiny"
          callback      : (state) =>
            if state
            then computeController.start data
            else computeController.stop data
            @destroy()
        publicIp        :
          label         : "Public IP"
          cssClass      : if running then "custom-link-view" else "hidden"
          itemClass     : KDView
          partial       : data.ipAddress or "N/A"
        specs           :
          label         : 'Specs'
          itemClass     : KDView
          partial       : "1GB Ram, 1Core, #{storage}GB Disk"
        provider        :
          label         : "Provider"
          itemClass     : CustomLinkView
          title         : KD.config.providers[data.provider]?.name or "Unknown"
          href          : KD.config.providers[data.provider]?.link or "/"
        guides          :
          label         : 'Guides'
          itemClass     : GuidesLinksView

    super options, data

    { computeController } = KD.singletons

  viewAppended:->

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position :
        top    : 20
