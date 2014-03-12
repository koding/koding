class VMSelection extends KDModalView

  constructor:(options={}, data)->

    super
      width           : 400
      title           : "Select a VM"
      overlay         : yes
      draggable       : no
      cancellable     : yes
      appendToDomBody : yes
      delegate        : options.delegate
    , data

    @setClass 'vm-selection'

  viewAppended:->

    @addSubView view = new KDCustomHTMLView tagName : 'ul'

    { vmController } = KD.singletons
    { vms }          = vmController

    vmController.on 'vm.progress.start', ({alias, update}) => @[alias].handleVMStart update
    vmController.on 'vm.progress.stop',  ({alias, update}) => @[alias].handleVMStop update
    vmController.on 'vm.state.info',     ({alias, state})  => @[alias].handleVMInfo state

    @addSubView ul = new KDCustomHTMLView tagName : 'ul'

    vms.forEach (vm)=>
      alias             = vm.hostnameAlias
      @[alias] = new TerminalStartTabVMItem {}, vm
      ul.addSubView @[alias]
      appView = @getDelegate()
      @[alias].on 'VMItemClicked', (vm)=>
        appView.emit 'VMItemClicked', vm

    for own alias, kite of vmController.kites
      if kite.recentState
        @[alias].handleVMInfo kite.recentState

