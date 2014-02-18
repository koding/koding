class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

  viewAppended:->

    @addSubView new KDView
      cssClass : 'environment-help'
      partial  : """
        <h1>Environments</h1>
      """

    @addSubView @freePlanView = new KDView
      cssClass : "top-warning"
      partial  : """
        You are on a free developer plan, see your usage or <a href="/Pricing">upgrade</a>.
      """

    @paymentController = KD.getSingleton("paymentController")
    @paymentController.fetchActiveSubscription tags: "vm", (err, subscription) =>
      return console.error err  if err
      @freePlanView.show()  if not subscription or "nosync" in subscription.tags

    @paymentController.on "SubscriptionCompleted", =>
      @freePlanView.hide()

    @addSubView new StackView {}, title:"Your default stack"
    # @addSubView new StackView {}, title:"Extended stack"

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
        @setHeight if @getHeight() < 300 then 530 else 36

    # Main scene for DIA
    @addSubView scene = new EnvironmentScene

    # Rules Container
    rulesContainer = new EnvironmentRuleContainer
    scene.addContainer rulesContainer
    rulesContainer.on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more rules will be available soon."
    # rulesContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # Domains Container
    domainsContainer = new EnvironmentDomainContainer
    scene.addContainer domainsContainer
    domainsContainer.on "itemRemoved", scene.bound 'updateConnections'

    # VMs / Machines Container
    machinesContainer = new EnvironmentMachineContainer
    scene.addContainer machinesContainer

    _containers = [machinesContainer, domainsContainer]

    # Rules Container
    extrasContainer = new EnvironmentExtraContainer
    scene.addContainer extrasContainer
    extrasContainer.on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more resource will be available soon."

    _containers = _containers.concat [rulesContainer, extrasContainer]

    for container in _containers
      container.on 'DataLoaded', scene.bound 'updateConnections'

    refreshContainers = ->
      # After Domains and Machines container load finished
      # Call updateConnections to draw lines between corresponding objects
      scene.whenItemsLoadedFor _containers, =>
        scene.updateConnections()
    refreshContainers()

    KD.getSingleton("vmController").on 'VMListChanged', -> refreshContainers()

    # Plus button on domainsContainer opens up the domainCreateModal
    domainsContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      return if machinesContainer.diaCount() is 0
        new KDNotificationView
          title: "You need to have at least one VM to manage domains."

      domainCreateForm = @getDomainCreateForm domainsContainer

      new KDModalView
        title          : "Add Domain"
        view           : domainCreateForm
        width          : 700
        buttons        :
          createButton :
            title      : "Create"
            style      : "modal-clean-green"
            callback   : =>
              domainCreateForm.createSubDomain()

    vmController = KD.getSingleton 'vmController'

    vmController.on "VMPlansFetchStart", =>
      machinesContainer.showLoader()

    vmController.on "VMPlansFetchEnd", =>
      machinesContainer.hideLoader()

    machinesContainer.on 'PlusButtonForGroupsClicked', ->
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      KD.remote.api.JVM.createSharedVm (err, vm)->
        return KD.showError err  if err
        vmc = KD.getSingleton("vmController")
        vmc.emit 'VMListChanged'

    # Plus button on machinesContainer uses the vmController
    machinesContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      @addVmModal = new KDModalView
        title        : 'Add Virtual Machine'
        cssClass     : 'add-vm-modal'
        view         : @getVmSelectionView()
        width        : 786
        buttons      :
          create     :
            title    : "Create"
            style    : "modal-clean-green"
            callback : =>
              @addVmModal.destroy()
              KD.singleton("vmController").createNewVM (err) ->
                KD.showError err

  getDomainCreateForm: (domainsContainer)->
    domainCreateForm = new DomainCreateForm
    domainsContainer.on "itemRemoved", domainCreateForm.bound "updateDomains"
    domainCreateForm.on "DomainSaved", domainsContainer.bound "loadItems"
    return domainCreateForm

  getVmSelectionView: ->
    addVmSelection = new KDCustomHTMLView
      cssClass   : "new-vm-selection"

    addVmSelection.addSubView addVmSmall = new KDCustomHTMLView
      cssClass    : "add-vm-box selected"
      partial     :
        """
          <h3>Small <cite>1x</cite></h3>
          <ul>
            <li><strong>1</strong> CPU</li>
            <li><strong>1GB</strong> RAM</li>
            <li><strong>4GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Large <cite>2x</cite></h3>
          <ul>
            <li><strong>2</strong> CPU</li>
            <li><strong>2GB</strong> RAM</li>
            <li><strong>8GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmExtraLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Extra Large <cite>3x</cite></h3>
          <ul>
            <li><strong>4</strong> CPU</li>
            <li><strong>4GB</strong> RAM</li>
            <li><strong>16GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView comingSoonTitle = new KDCustomHTMLView
      cssClass     : "coming-soon-title"
      tagName      : "h5"
      partial      : "Coming soon..."

    return addVmSelection
