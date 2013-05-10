class NVMItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass or= "vm"
    super options, data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    # @vmToggle  = new KDOnOffSwitch
    #   cssClass : "tiny vm-toggle"
    #   callback : (state)=>
    #     if state then @vm.start() else @vm.stop()

    # @vmResetButton = new KDButtonView
    #   cssClass     : "vmreinitialize-button"
    #   iconOnly     : yes
    #   iconClass    : "cog"
    #   tooltip      :
    #     title      : "Re-initialize your VM"
    #   callback     : => @vm.reinitialize()

  checkVMState:(err, info)->
    if err or not info
      @unsetClass 'online'
      # @vmToggle.setDefaultValue no
      return warn err

    switch info.state
      when "RUNNING"
        @setClass 'online'
        # @vmToggle.setDefaultValue yes

      when "STOPPED"
        @unsetClass 'online'
        # @vmToggle.setDefaultValue no

  viewAppended:->
    super
    @vm.info @bound 'checkVMState'

  pistachio:->

    """
      {{> @icon}}
      {{> @loader}}
      {span.title{ #(name)}}
      <span class='chevron'></span>
    """
