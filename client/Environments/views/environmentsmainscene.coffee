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
          Welcome to Environments. Here you can setup your servers and development environment.
        </div>
      """

    @addSubView @freePlanView = new KDView
      cssClass : "top-warning"
      partial  : """
        <div class="content">
          You are on a free developer plan, see your usage or <a href="/Pricing">upgrade</a>.
        </div>
      """

    @paymentController = KD.getSingleton("paymentController")
    @paymentController.fetchActiveSubscription tags: "vm", (err, subscription) =>
      return console.error err  if err
      @freePlanView.show()  if not subscription or "nosync" in subscription.tags

    @paymentController.on "SubscriptionCompleted", =>
      @freePlanView.updatePartial ""

    @fetchStacks()

  fetchStacks:->

    {JStack} = KD.remote.api

    JStack.getStacks (err, stacks)=>
      return KD.showError err  if err

      stacks.forEach (stack)=>

        title   = stack.meta?.title
        number  = if stack.sid > 0 then "#{stack.sid}." else "default"
        title or= "Your #{number} environment stack on #{stack.group}"

        @addSubView new StackView {}, {title, stack}

class StackView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'environment-stack'
    super options, data

  viewAppended:->

    @addSubView title = new KDView
      cssClass : 'stack-title'
      partial  : @getData().title

    @addSubView new KDButtonView
      title    : 'Details'
      cssClass : 'stack-toggle'
      callback : =>
        @setHeight if @getHeight() < 300 then 600 else 36
        KD.utils.wait 300, @bound 'updateView'

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    # Rules Container
    rulesContainer = new EnvironmentRuleContainer
    @scene.addContainer rulesContainer

    # Domains Container
    domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer domainsContainer

    domainsContainer.on 'itemRemoved', @lazyBound('updateView', yes)
    domainsContainer.on 'itemAdded',   @lazyBound('updateView', yes)

    # VMs / Machines Container
    machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer machinesContainer
    machinesContainer.on 'VMListChanged', @lazyBound('updateView', yes)

    # Rules Container
    extrasContainer = new EnvironmentExtraContainer
    @scene.addContainer extrasContainer

    @loadContainers()

  loadContainers:->
    promises = (container.loadItems()  for container in @scene.containers)
    Promise.all(promises).then => @updateView yes

  updateView:(updateData = no)->

    @scene.updateConnections()  if updateData

    @scene.highlightLines()
    @scene.updateScene()
