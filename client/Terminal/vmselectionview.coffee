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

    vmController.on 'vm.start.progress', (alias, update) => @[alias].handleVMStart update
    vmController.on 'vm.stop.progress',  (alias, update) => @[alias].handleVMStop update
    vmController.on 'vm.info.state',     (alias, update) => @[alias].handleVMInfo update

    @addSubView ul = new KDCustomHTMLView tagName : 'ul'

    vms.forEach (vm)=>
      alias             = vm.hostnameAlias
      @[alias] = new TerminalStartTabVMItem {}, vm
      ul.addSubView @[alias]
      appView = @getDelegate()
      @[alias]
        .once('vm.is.prepared', @bound 'destroy')
        .once 'VMItemClicked', (vm)=>
          appView.emit 'VMItemClicked', vm
          @destroy()

    for own alias, kite of vmController.kites
      if kite.recentState
        @[alias].handleVMInfo kite.recentState

