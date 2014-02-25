class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

  viewAppended:->

    @addSubView new KDView
      cssClass : 'environment-help'
      partial  : """
        <div class="content">
          <h1>Environments</h1>
          Welcome to Environments.
          Here you can setup your servers and development environment.
        </div>
      """

    @addSubView freePlanView = new KDView
      cssClass : "top-warning"
      click    : (event) ->
        if "usage" in event.target.classList
          KD.utils.stopDOMEvent event
          new KDNotificationView title: "Coming soon..."

    paymentControl = KD.getSingleton("paymentController")
    paymentControl.fetchActiveSubscription tags: "vm", (err, subscription) ->
      return warn err  if err
      if not subscription or "nosync" in subscription.tags
        freePlanView.updatePartial """
          <div class="content">
            You are on a free developer plan,
            see your <a class="usage" href="#">usage</a> or
            <a class="pricing" href="/Pricing">upgrade</a>.
          </div>
        """

    paymentControl.on "SubscriptionCompleted", ->
      freePlanView.updatePartial ""

    @addSubView controlPanel = new KDView
      cssClass : "control-panel"

    controlPanel.addSubView @createStackButton = new KDButtonView
      cssClass : "create-stack-button solid mini green"
      title    : "Create a new stack"
      callback : => new KDNotificationView title: "Coming soon!"

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


class StackView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'environment-stack'
    super options, data

  viewAppended:->

    @addSubView title = new KDView
      cssClass : 'stack-title'
      partial  : @getData().title

    @addSubView toggle = new KDButtonView
      title    : 'Hide details'
      cssClass : 'stack-toggle solid mini'
      callback : =>
        if @getHeight() <= 50
          @setHeight @getProperHeight()
          toggle.setTitle 'Hide details'
        else
          toggle.setTitle 'Show details'
          @setHeight 48
        KD.utils.wait 300, @bound 'updateView'

    @addSubView dump = new KDButtonView
      title    : 'Show dump'
      cssClass : 'stack-dump solid mini'
      callback : @bound 'dumpStack'

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    # Rules Container
    rulesContainer = new EnvironmentRuleContainer
    @scene.addContainer rulesContainer

    # Domains Container
    domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer domainsContainer
    domainsContainer.on 'itemAdded',   @lazyBound('updateView', yes)

    # VMs / Machines Container
    machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer machinesContainer
    machinesContainer.on 'VMListChanged', @bound 'loadContainers'

    # Rules Container
    extrasContainer = new EnvironmentExtraContainer
    @scene.addContainer extrasContainer

    @loadContainers()

  loadContainers:->

    return  if @_inProgress
    @_inProgress = yes

    promises = (container.loadItems()  for container in @scene.containers)
    Promise.all(promises).then =>
      @setHeight @getProperHeight()
      KD.utils.wait 300, =>
        @_inProgress = no
        @updateView yes

  updateView:(updateData = no)->

    @scene.updateConnections()  if updateData

    if @getHeight() > 50
      @setHeight @getProperHeight()

    @scene.highlightLines()
    @scene.updateScene()

  getProperHeight:->
    (Math.max.apply null, (box.diaCount() for box in @scene.containers)) * 45 + 170
