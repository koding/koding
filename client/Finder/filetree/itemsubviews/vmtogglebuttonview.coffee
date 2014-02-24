class NVMToggleButtonView extends JView

  constructor:(options, data)->
    super cssClass: 'vm-toggle-menu', data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    @menuTitle = new KDCustomHTMLView
      tagName : 'span'
      partial : 'Fetching VM state...'

    @toggle = new KDOnOffSwitch
      cssClass : "tiny vm-toggle-item hidden"
      callback : (state)=>
        if state
        then @vm.start @getData().vmName
        else @vm.stop  @getData().vmName

    @loader = new KDLoaderView
      cssClass      : 'vm-toggle-item'
      showLoader    : yes
      size          : width : 12
      loaderOptions :
        speed       : 0.7
        FPS         : 24

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    if err or not info

      @notification?.destroy()
      @notification = new KDNotificationView
        type    : "mini"
        cssClass: "error"
        duration: 5000
        title   : "Still waiting... This VM is booting slowly."

      @toggle.setDefaultValue no
      # KD.utils.notifyAndEmailVMTurnOnFailureToSysAdmin vm, err.message
      KD.logToExternal "oskite: vm failed to turn on", {error:err.message, vm}
      return warn err

    if info.state is "RUNNING"
    then @toggle.setDefaultValue yes
    else @toggle.setDefaultValue no

    @menuTitle.updatePartial 'Change state'
    @toggle.show()
    @loader.hide()

  pistachio:->
    """{{> @menuTitle}}{{> @toggle}}{{> @loader}}"""

  viewAppended:->
    super
    @loader.show()
    @vm.info @getData().vmName, @bound 'checkVMState'