class TerminalStartTab extends JView

  constructor:->

    super

    @vmWrapper = new KDCustomHTMLView tagName : 'ul'


  viewAppended:->

    super

    @fetchVMs()


  fetchVMs:->

    {vmController} = KD.singletons

    vmController.fetchVMs (err, vms)=>

      if err
        return new KDNotificationView title : "Couldn't fetch your VMs"

      vms.sort (a,b)-> a.hostnameAlias > b.hostnameAlias

      @listVMs vms

      for own alias, kite of vmController.kites
        if kite.recentState
          @vmWrapper[alias].handleVMInfo kite.recentState

    vmController.on 'vm.progress.start', ({alias, update}) => @vmWrapper[alias].handleVMStart update
    vmController.on 'vm.progress.stop',  ({alias, update}) => @vmWrapper[alias].handleVMStop update
    vmController.on 'vm.state.info',     ({alias, state})  => @vmWrapper[alias].handleVMInfo state


  listVMs:(vms)->

    vms.forEach (vm)=>
      alias             = vm.hostnameAlias
      @vmWrapper[alias] = new TerminalStartTabVMItem {}, vm
      @vmWrapper.addSubView @vmWrapper[alias]
      appView = @getDelegate()
      appView.forwardEvent @vmWrapper[alias], 'VMItemClicked'

  pistachio:->
    """
    <h1>This is where the magic happens!</h1>
    <h2>Terminal allows you to interact directly with your VM.</h2>
    <figure><iframe src="//www.youtube.com/embed/DmjWnmSlSu4?origin=https://koding.com&showinfo=0&rel=0&theme=dark&modestbranding=1&autohide=1&loop=1" width="100%" height="100%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe></figure>
    <h3>Your VMs</h3>
    {{> @vmWrapper}}
    """