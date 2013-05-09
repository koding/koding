class NVMToggleButtonView extends JView

  constructor:(options, data)->
    super cssClass: 'vm-toggle-menu', data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    @toggle = new KDOnOffSwitch
      cssClass : "tiny vm-toggle-item"
      callback : (state)=>
        if state then @vm.start() else @vm.stop()

  checkVMState:(err, info)->
    if err or not info
      @toggle.setDefaultValue no
      return warn err

    if info.state is "RUNNING"
    then @toggle.setDefaultValue yes
    else @toggle.setDefaultValue no

  pistachio:->
    """<span>Change state</span> {{> @toggle}}"""

  viewAppended:->
    super
    @vm.info @bound 'checkVMState'