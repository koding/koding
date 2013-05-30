class NMountToggleButtonView extends JView

  constructor:(options, data)->
    super cssClass: 'vm-toggle-menu', data

    @toggle = new KDOnOffSwitch
      cssClass : "tiny vm-toggle-item"
      callback : (state)=>
        fc = KD.singletons.finderController
        if state
        then fc.mountVm   @getData().vmName
        else fc.unmountVm @getData().vmName

  checkMountState:->

    {vmName} = @getData()
    fc = KD.singletons.finderController
    for vm in fc.vms  when vm.vmName is vmName
      @toggle.setDefaultValue yes
      return
    @toggle.setDefaultValue no

  pistachio:->
    """<span>Show in Filetree</span> {{> @toggle}}"""

  viewAppended:->
    super
    @checkMountState()
