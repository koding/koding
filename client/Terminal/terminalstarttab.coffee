class TerminalStartTab extends JView

  constructor:->

    super

    @vmWrapper = new KDCustomHTMLView tagName : 'ul'

    @message = new KDCustomHTMLView cssClass : 'terminal-bottom-message'
    @message.hide()

    KD.singletons.notificationController.on 'NotificationHasArrived', ({event}) =>
      if event in ["VMCreated", "VMRemoved"]

        @viewAppended yes

  viewAppended: (force = no) ->

    super
    @fetchVMs force
    @prepareMessage()


  fetchVMs: (force = no) ->

    {vmController, kontrol} = KD.singletons

    vmController.fetchVMs force, (err, vms)=>
      if err
        ErrorLog.create "terminal: Couldn't fetch vms", reason:err
        return new KDNotificationView title : "Couldn't fetch your VMs"

      vms.sort (a,b)-> a.hostnameAlias > b.hostnameAlias

      @listVMs vms

      terminalKites = kontrol.kites.terminal

      vmController.on 'terminalsReady', =>
        @listVMSessions vms

      osKites = kontrol.kites.oskite

      for own alias, kite of osKites
        if kite.recentState
          @vmWrapper[alias]?.handleVMInfo kite.recentState

    vmController.on 'vm.progress.start', ({alias, update}) => @vmWrapper[alias]?.handleVMStart update
    vmController.on 'vm.progress.stop',  ({alias, update}) => @vmWrapper[alias]?.handleVMStop update
    vmController.on 'vm.state.info',     ({alias, state})  => @vmWrapper[alias]?.handleVMInfo state
    vmController.on 'vm.progress.error', ({alias, error}) => @vmWrapper[alias]?.handleVMError error


  listVMs:(vms)->

    @vmWrapper.destroySubViews()
    vms.forEach (vm)=>
      alias             = vm.hostnameAlias
      @vmWrapper[alias] = new TerminalStartTabVMItem {}, vm
      @vmWrapper.addSubView @vmWrapper[alias]
      appView = @getDelegate()
      appView.forwardEvent @vmWrapper[alias], 'VMItemClicked'


  listVMSessions: (vms) ->
    {vmController, kontrol} = KD.singletons
    vmList = {}
    vms.forEach (vm) -> vmList[vm.hostnameAlias] = vm

    terminalKites = kontrol.kites.terminal

    delegate = @getDelegate()

    for own alias, kite of terminalKites
      vm = vmList[alias]
      @vmWrapper[alias].addSubView new SessionStackView {kite, alias, vm, delegate}


  pistachio:->

    """
    <h1>This is where the magic happens!</h1>
    <h3>Your VMs</h3>
    {{> @vmWrapper}}
    <figure><iframe src="//www.youtube.com/embed/DmjWnmSlSu4?origin=https://koding.com&showinfo=0&rel=0&theme=dark&modestbranding=1&autohide=1&loop=1" width="100%" height="100%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe></figure>
    <h2>Terminal allows you to interact directly with your VM.</h2>
    {{> @message}}
    """

  prepareMessage: ->

    {paymentController} = KD.singletons
    paymentController.fetchActiveSubscription tags: "vm", (err, subscription) =>
      return error err  if err
      if not subscription or "nosync" in subscription.tags
        message = """You are on a free developer plan. Your VMs will be turned off within 15 minutes of idle time,
        and all your sessions will be deleted. If you want to keep your sessions, you can
        <a class="pricing" href="/Pricing">upgrade</a> your current plan and use Always On VMs."""
      else
        message = """If you have active sessions which do not belong to an Always-on VM, you can lose your sessions 15 minutes after you log out or if you leave them idle."""
      @message.updatePartial message
      @message.show()




