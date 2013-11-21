class NMountToggleButtonView extends JView

  constructor:(options, data)->
    super
      cssClass     : 'vm-toggle-menu'
      defaultLabel : options.defaultLabel ? "<span>Show in Filetree</span>"
    , data

    @toggle = new KDOnOffSwitch
      cssClass : "tiny vm-toggle-item"
      callback : (state)=>
        fc = KD.getSingleton("finderController")
        if state
        then fc.mountVm   @getData().vmName
        else fc.unmountVm @getData().vmName

  checkMountState:->

    {vmName} = @getData()
    fc = KD.getSingleton("finderController")
    for vm in fc.vms  when vm.vmName is vmName
      @toggle.setDefaultValue yes
      return
    @toggle.setDefaultValue no

  pistachio:->
    """#{@getOption 'defaultLabel'}{{> @toggle}}"""

  viewAppended:->
    super
    @checkMountState()
