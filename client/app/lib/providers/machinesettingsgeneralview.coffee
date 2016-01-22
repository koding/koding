kd                     = require 'kd'
KDView                 = kd.View
Encoder                = require 'htmlencode'
Machine                = require './machine'
showError              = require 'app/util/showError'
selectText             = require 'app/util/selectText'
KodingSwitch           = require '../commonviews/kodingswitch'
KDLoaderView           = kd.LoaderView
CustomLinkView         = require '../customlinkview'
CopyTooltipView        = require 'app/components/common/copytooltipview'
KDCustomHTMLView       = kd.CustomHTMLView
KDHitEnterInputView    = kd.HitEnterInputView
KDFormViewWithFields   = kd.FormViewWithFields
ComputeErrorUsageModal = require './computeerrorusagemodal'


module.exports = class MachineSettingsGeneralView extends KDView

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

      label = Encoder.XSSEncode newLabel

      nickname.updatePartial "<span class='edit'>update</span> #{label}"

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

    { nickname, nickEdit, buildlogs, publicIp } = @form.inputs

    nickname.on 'click', (e) =>

      return  unless e.target.tagName is 'SPAN'

      nickname.hide()

      kd.singletons.windowController.addLayer nickEdit
      nickEdit.once 'ReceivedClickElsewhere', ->
        nickEdit.hide()
        nickname.show()

      nickEdit.setValue Encoder.htmlDecode @machine.label
      nickEdit.show()

      kd.utils.defer -> nickEdit.setFocus()

    buildlogs.on 'click', (e) =>

      return  unless @machine.isRunning()
      return  unless e.target.tagName is 'SPAN'

      buildlogs.updatePartial 'loading...'
      kd.singletons.computeController.showBuildLogs @machine
      kd.utils.wait 1000, @lazyBound 'emit', 'ModalDestroyRequested'


    publicIp.on 'click', ->
      selectText publicIp.getElement()
      publicIp.showTooltip()


  createForm: ->

    isAws       = @machine.provider is 'aws'
    running     = @machine.status.state in [ Running, Starting ]
    accessUri   = "http://#{@machine.domain}"
    isManaged   = @machine.isManaged()
    logsMessage = if @machine.isRunning() \
      then "<span class='logs-link'>show logs</span>"
      else "Please turn on the machine to see logs"

    publicIpView = new KDView
      partial   : @machine.ipAddress or 'N/A'

    @addSubView @form = new KDFormViewWithFields
      cssClass          : 'AppModal-form'
      fields            :
        statusToggle    :
          cssClass      : if isManaged then 'hidden'
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
        alwaysOn        :
          label         : 'Keep VM always on'
          defaultValue  : @machine.alwaysOn
          itemClass     : KodingSwitch
          cssClass      : if isManaged then 'statustoggle hidden' else 'statustoggle'
          disabled      : @machine.isPermanent()
          callback      : @bound 'handleAlwaysOnStateChanged'
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
          itemClass     : CopyTooltipView
          childView     : publicIpView
          cssClass      : if running then 'custom-link-view' else 'hidden'
        accessUri       :
          label         : 'Assigned URL'
          cssClass      : if isManaged or isAws then 'assigned-url hidden' else 'assigned-url'
          itemClass     : CustomLinkView
          title         : @machine.domain
          href          : accessUri
          target        : '_blank'
        buildlogs       :
          label         : 'Build logs'
          cssClass      : if isAws then 'custom-link-view' else 'hidden'
          itemClass     : KDView
          partial       : logsMessage
