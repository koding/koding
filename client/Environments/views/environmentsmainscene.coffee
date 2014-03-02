class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

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

    EnvironmentDataProvider.get (data) =>

      {JStack} = KD.remote.api
      JStack.getStacks (err, stacks)=>
        warn err  if err

        group = KD.getGroup().title
        if not stacks or stacks.length is 0
          stacks = [{sid:0, group}]

        @_stacks = []
        stacks.forEach (stack, index)=>
          @_stacks.push @addSubView new StackView \
            {stack, isDefault: index is 0}, data

          callback?()  if index is stacks.length - 1


