kd                   = require 'kd'
KDView               = kd.View
Machine              = require './machine'
KodingSwitch         = require '../commonviews/kodingswitch'
KDLoaderView         = kd.LoaderView
CustomLinkView       = require '../customlinkview'
KDCustomHTMLView     = kd.CustomHTMLView
KDHitEnterInputView  = kd.HitEnterInputView
KDFormViewWithFields = kd.FormViewWithFields


module.exports = class MachineGeneralSettingsView extends KDView

  { Running, Starting } = Machine.State

  constructor: (options, data) ->

    super options, data

    @machine = @getData()

    @createForm()
    @fetchMachineState()


  handleMachineStateChanged: (state) ->

    method = if state then 'start' else 'stop'

    kd.singletons.computeController[method] @machine

    @emit 'ModalDestroyRequested'


  fetchMachineState: ->

    machineId    = @machine._id
    currentState = @machine.status.state

    { statusToggle, statusLoader } = @form.inputs

    statusToggle.hide()

    kd.singletons.computeController.getKloud()

      .info { machineId, currentState }
      .then (response) =>

        if   response.State is Running
        then statusToggle.setOn  no
        else statusToggle.setOff no

        statusToggle.show()
        statusLoader.hide()

      .catch (err) =>

        kd.warn 'Failed to fetch info for machine settings:', err
        statusLoader.hide()
        statusToggle.setOff no
        statusToggle.show()


  createForm: ->

    running   = @machine.status.state in [ Running, Starting ]
    accessUri = "http://#{@machine.domain}"

    @addSubView @form = new KDFormViewWithFields
      cssClass          : 'AppModal-form'
      fields            :
        statusToggle    :
          label         : 'On/Off'
          cssClass      : 'tiny'
          defaultValue  : running
          itemClass     : KodingSwitch
          disabled      : @machine.isPermanent()
          callback      : @bound 'handleMachineStateChanged'
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
        nickname        :
          label         : 'Nickname'
          cssClass      : 'custom-link-view'
          itemClass     : KDView
          partial       : @machine.label
          nextElement   :
            nickEdit    :
              itemClass : KDHitEnterInputView
              type      : 'text'
              cssClass  : 'hidden'
              attributes: spellcheck: false
              callback  : => @emit 'UpdateNickname'
        publicIp        :
          label         : 'Public IP'
          cssClass      : if running then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : @machine.ipAddress or 'N/A'
        accessUri       :
          label         : 'Assigned URL'
          cssClass      : 'assigned-url'
          itemClass     : CustomLinkView
          title         : @machine.domain
          href          : accessUri
          target        : '_blank'
          tooltip       :
            title       : accessUri
            placement   : 'top'
