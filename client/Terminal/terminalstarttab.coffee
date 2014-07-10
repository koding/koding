class TerminalStartTab extends JView

  constructor:->

    super

    @machineWrapper = new KDCustomHTMLView tagName : 'ul'

    @message = new KDCustomHTMLView cssClass : 'terminal-bottom-message'
    @message.hide()

    # FIXME GG
    # KD.singletons.notificationController.on 'NotificationHasArrived', ({event}) =>
    #   if event in ["VMCreated", "VMRemoved"]
    #     @viewAppended yes

  viewAppended: ->

    super
    @fetchMachines()
    @prepareMessage()


  fetchMachines: ->

    {computeController} = KD.singletons
    computeController.fetchMachines (err, machines)=>

      if err
        ErrorLog.create "terminal: Couldn't fetch machines", reason:err
        return new KDNotificationView title : "Couldn't fetch your Machines"

      machines = machines.filter (machine)-> machine.status.state is "Running"

      @listMachines        machines
      @listMachineSessions machines


  listMachines: (machines)->

    @machineWrapper.destroySubViews()

    machines.forEach (machine)=>

      @machineWrapper.addSubView @machineWrapper[machine.uid] = \
        new TerminalStartTabVMItem {}, machine

      @getDelegate().forwardEvent @machineWrapper[machine.uid], 'VMItemClicked'


  listMachineSessions: (machines) ->

    machines.forEach (machine)=>

      @machineWrapper[machine.uid].addSubView \
        new SessionStackView { machine, delegate: @getDelegate() }


  pistachio:->

    """
    <h1>This is where the magic happens!</h1>
    <h3>Your VMs</h3>
    {{> @machineWrapper}}
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




