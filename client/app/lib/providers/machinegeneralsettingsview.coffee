kd                   = require 'kd'
KDView               = kd.View
Machine              = require './machine'
showError            = require 'app/util/showError'
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

    @bindViewEvents()


  handleMachineStateChanged: (state) ->

    method = if state then 'start' else 'stop'

    kd.singletons.computeController[method] @machine

    @emit 'ModalDestroyRequested'


  handleAlwaysOnStateChanged: (state) ->

    { alwaysOn } = @form.inputs
    { computeController } = kd.singletons

    computeController.fetchUserPlan (plan) =>

      computeController.setAlwaysOn @machine, state, (err) =>

        return  unless err

        if err.name is 'UsageLimitReached' and plan isnt 'hobbyist'
          @emit 'ModalDestroyRequested'
          kd.utils.defer => new ComputeErrorUsageModal { plan }
        else
          showError err

        alwaysOn.setOff no


  handleNicknameUpdate: ->

    { nickEdit, nickname } = @form.inputs
    newLabel = nickEdit.getValue()

    if kd.utils.slugify(newLabel) is ''
      return showError 'Nickname cannot be empty.'

    @machine.setLabel newLabel, (err, newSlug) =>

      return if showError err

      nickname.updatePartial "<span class='edit'>update</span> #{newLabel}"

      nickEdit.hide()
      nickname.show()

      @machine.emit 'MachineLabelUpdated', newLabel, newSlug
      # @emit 'ModalDestroyRequested'


  fetchMachineState: ->

    machineId    = @machine._id
    currentState = @machine.status.state

    { statusToggle, statusLoader } = @form.inputs

    statusToggle.hide()

    kd.singletons.computeController.getKloud()

      .info { machineId, currentState }
      .then (response) ->

        if   response.State is Running
        then statusToggle.setOn  no
        else statusToggle.setOff no

        statusToggle.show()
        statusLoader.hide()

      .catch (err) ->

        kd.warn 'Failed to fetch info for machine settings:', err
        statusLoader.hide()
        statusToggle.setOff no
        statusToggle.show()


  bindViewEvents: ->

    { nickname, nickEdit } = @form.inputs

    nickname.on 'click', (e) =>

      return  unless e.target.tagName is 'SPAN'

      nickname.hide()

      kd.singletons.windowController.addLayer nickEdit
      nickEdit.once 'ReceivedClickElsewhere', ->
        nickEdit.hide()
        nickname.show()

      nickEdit.setValue @machine.label
      nickEdit.show()

      kd.utils.defer -> nickEdit.setFocus()


  createForm: ->

    running   = @machine.status.state in [ Running, Starting ]
    accessUri = "http://#{@machine.domain}"

    @addSubView @form = new KDFormViewWithFields
      cssClass          : 'AppModal-form'
      fields            :
        statusToggle    :
          label         : 'On/Off'
          defaultValue  : running
          itemClass     : KodingSwitch
          disabled      : @machine.isPermanent()
          callback      : @bound 'handleMachineStateChanged'
          nextElement   :
            statusLoader:
              itemClass : KDLoaderView
              cssClass  : 'in-progress'
              size      :
                width   : 16
                height  : 16
              loaderOptions :
                color   : '#333333'
              showLoader: yes
        nickname        :
          label         : 'Nickname'
          cssClass      : 'custom-link-view'
          itemClass     : KDView
          partial       : "<span class='edit'>update</span> #{@machine.label}"
          nextElement   :
            nickEdit    :
              itemClass : KDHitEnterInputView
              type      : 'text'
              cssClass  : 'hidden'
              attributes: spellcheck: false
              callback  : => @handleNicknameUpdate() # bound won't work.
        publicIp        :
          label         : 'Public IP'
          cssClass      : if running then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : @machine.ipAddress or 'N/A'
        alwaysOn        :
          label         : 'Keep VM always on'
          defaultValue  : @machine.alwaysOn
          itemClass     : KodingSwitch
          disabled      : @machine.isPermanent()
          callback      : @bound 'handleAlwaysOnStateChanged'
        accessUri       :
          label         : 'Assigned URL'
          cssClass      : 'assigned-url'
          itemClass     : CustomLinkView
          title         : @machine.domain
          href          : accessUri
          target        : '_blank'