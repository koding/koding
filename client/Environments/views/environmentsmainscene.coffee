class EnvironmentsMainScene extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-content', options.cssClass

    super options, data

    @on "NewStackRequested",   @bound "createNewStack"
    @on "CloneStackRequested", @bound "cloneStack"

  viewAppended:->

    @addSubView header = new KDView
      tagName  : 'header'
      partial  : """
        <h1>Environments</h1>
        <div class="content">
          Welcome to Environments.
          Here you can setup your servers and development environment.
        </div>
      """

    freePlanView = new KDView
      cssClass : "top-warning"
      click    : (event) ->
        if "usage" in event.target.classList
          KD.utils.stopDOMEvent event
          new KDNotificationView title: "Coming soon..."

    header.addSubView freePlanView

    paymentControl = KD.getSingleton("paymentController")
    paymentControl.fetchActiveSubscription tags: "vm", (err, subscription) ->
      return warn err  if err
      if not subscription or "nosync" in subscription.tags
        freePlanView.updatePartial """
          You are on a free developer plan,
          see your <a class="usage" href="#">usage</a> or
          <a class="pricing" href="/Pricing">upgrade</a>.
        """

    paymentControl.on "SubscriptionCompleted", ->
      freePlanView.updatePartial ""

    @fetchStacks()

  fetchStacks: (callback)->

    EnvironmentDataProvider.get (@environmentData) =>
      # console.clear()
      # log "environment data", @environmentData

      {JStack} = KD.remote.api
      JStack.getStacks (err, stacks = [])=>
        warn err  if err
        @createStacks stacks

  createStacks: (stacks) ->
    @_stacks = []
    stacks.forEach (stack, index) =>
      stack = new StackView  { stack, isDefault: index is 0 }, @environmentData
      @_stacks.push @addSubView stack
      @forwardEvent stack, "NewStackRequested"
      @forwardEvent stack, "CloneStackRequested"

      callback?()  if index is stacks.length - 1

  createNewStack: (meta, modal) ->
    KD.remote.api.JStack.createStack meta, (err, stack) =>
      title = "Failed to create a new stack. Try again later!"
      return new KDNotificationView { title }  if err
      modal.destroy()

      stackView = new StackView { stack} , @environmentData
      @_stacks.push @addSubView stackView

      stackView.once "transitionend", =>
        stackView.getElement().scrollIntoView()
        KD.utils.wait 300, => # wait for a smooth feedback
          stackView.setClass "hilite"
          stackView.once "transitionend", =>
            stackView.setClass "hilited"

  cloneStack: (stackData) ->
    new CloneStackModal {}, stackData
