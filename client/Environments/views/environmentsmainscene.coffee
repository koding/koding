class EnvironmentsMainScene extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

    @stacks = []
    @on "CloneStackRequested", @bound "cloneStack"


  viewAppended:->

    @addSubView @renderHeader()
    { computeController, mainController } = KD.singletons
    computeController.on "renderStacks", @bound 'renderStacks'

    mainController.ready @bound 'renderStacks'
    @once 'NoStacksFound', computeController.bound 'createDefaultStack'

  renderStacks:->

    {computeController} = KD.singletons
    computeController.fetchStacks (err, stacks = [])=>

      (stack?.destroy?() for stack in @stacks)
      @stacks = []

      for stack, index in stacks
        @stacks.push @addSubView \
          stackView = new StackView {isDefault: index is 0}, stack
        @forwardEvent stackView, "CloneStackRequested"

      @emit "NoStacksFound"  if stacks.length is 0
      @emit "StacksCreated"


  createNewStack: (meta, modal)->

    KD.remote.api.JStack.create meta, (err, stack)=>

      title = "Failed to create a new stack. Try again later!"
      return new KDNotificationView { title }  if err?

      modal?.destroy()

      @stacks.push @addSubView stackView = new StackView {}, stack
      @forwardEvent stackView, "CloneStackRequested"

      @highlightStack stackView


  cloneStack: (stackData) ->

    return new KDNotificationView title: "FIXME ~GG"

    new CreateStackModal
      title   : "Give a title to your new stack"
      callback: (meta, modal) =>
        modal.destroy()
        stackModal = new CloneStackModal { meta }, stackData
        stackModal.once "StackCloned", =>
          @once "EnvironmentDataFetched", =>
            stackView.destroy() for stackView in @stacks
          @once "StacksCreated", =>
            @highlightStack @stacks.last
          @fetchStacks()


  highlightStack: (stackView) ->
    stackView.once "transitionend", ->
      stackView.getElement().scrollIntoView()
      KD.utils.wait 300, -> # wait for a smooth feedback
        stackView.setClass "hilite"
        stackView.once "transitionend", ->
          stackView.setClass "hilited"


  renderHeader: ->

    container = new KDCustomHTMLView
      tagName  : "section"
      cssClass : "environments-header"

    header = new KDView
      tagName  : 'header'
      partial  : """
        <h1>Environments</h1>
        <div class="content">
          Welcome to Environments.
          Here you can setup your servers and development environment.
        </div>
      """

    header.addSubView new KDButtonView
      title      : "Create a new stack"
      cssClass   : "solid green medium create-stack"
      callback   : => new CreateStackModal
        callback : @bound "createNewStack"

    header.addSubView freePlanView = new KDView
      cssClass : "top-warning"
      click    : (event) ->
        if "usage" in event.target.classList
          KD.utils.stopDOMEvent event
          new KDNotificationView title: "Coming soon..."

    paymentControl = KD.getSingleton("paymentController")
    paymentControl.fetchActiveSubscription tags: "vm", (err, subscription) ->
      return  if err
      if not subscription or "nosync" in subscription.tags
        freePlanView.updatePartial """
          You are on a free developer plan,
          see your <a class="usage" href="#">usage</a> or
          <a class="pricing" href="/Pricing">upgrade</a>.
        """

    paymentControl.on "SubscriptionCompleted", ->
      freePlanView.updatePartial ""

    container.addSubView header
    return container
