class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

  viewAppended:->

    @addSubView new KDView
      cssClass : 'environment-help'
      partial  : """
        <h1>Environments</h1>
        <div class='content'>
          <p>Welcome to environments.</p>
          <p>Here you can setup your development environment.</p>
          <p>Watch this quick video to learn more.</p>
          <div class='video'></div>
        </div>
      """

    # Action Area for Domains
    @addSubView actionArea = new KDView cssClass : 'action-area'

    # Domain Creation form in actionArea
    actionArea.addSubView @domainCreateForm = new DomainCreateForm

    # Domain Creation form connections
    @domainCreateForm.on 'CloseClicked', =>
      @unsetClass 'in-progress'
      @scene.unsetClass 'out'
      @domainCreateForm.unsetClass 'opened'
      @scene.off "click"

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    @addSubView new KDView
      cssClass : 'bottom-warning'
      partial  : """
        You are on a free plan, see your usage or <a href="/Pricing">upgrade</a>.
      """

    # if KD.checkFlag 'nostradamus'
    # Rules Container
    rulesContainer = new EnvironmentRuleContainer
    @scene.addContainer rulesContainer
    rulesContainer.on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more rules will be available soon."

    # rulesContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # Domains Container
    @domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer @domainsContainer
    @domainsContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # VMs / Machines Container
    @machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer @machinesContainer

    @_containers = [@machinesContainer, @domainsContainer]

    # if KD.checkFlag 'nostradamus'
    # Rules Container
    extrasContainer = new EnvironmentExtraContainer
    @scene.addContainer extrasContainer
    extrasContainer.on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more resource will be available soon."

    @_containers = @_containers.concat [rulesContainer, extrasContainer]

    for container in @_containers
      container.on 'DataLoaded', @scene.bound 'updateConnections'

    @refreshContainers()


    # @addSubView @resourcesContainer = new ResourcesContainer

    @domainCreateForm.on 'DomainSaved', @domainsContainer.bound 'loadItems'
    KD.getSingleton("vmController").on 'VMListChanged', \
                                        @bound 'refreshContainers'

    # Plus button on @domainsContainer opens up the action area
    @domainsContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      return if @machinesContainer.diaCount() is 0
        new KDNotificationView
          title: "You need to have at least one VM to manage domains."

      @setClass 'in-progress'
      @scene.setClass 'out'
      @domainCreateForm.setClass 'opened'
      @domainCreateForm.emit 'DomainNameShouldFocus'
      @utils.defer =>
        @scene.once 'click', => @domainCreateForm.emit 'CloseClicked'

    vmController = KD.getSingleton 'vmController'

    vmController.on "VMPlansFetchStart", =>
      @machinesContainer.showLoader()

    vmController.on "VMPlansFetchEnd", =>
      @machinesContainer.hideLoader()

    # Plus button on @machinesContainer uses the vmController
    @machinesContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      vmController.createNewVM()

    @machinesContainer.on 'PlusButtonForGroupsClicked', ->
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      KD.remote.api.JVM.createSharedVm (err, vm)->
        return KD.showError err  if err
        vmc = KD.getSingleton("vmController")
        vmc.emit 'VMListChanged'

    addVmSelection = new KDCustomHTMLView
      cssClass   : "new-vm-selection"

    addVmSelection.addSubView addVmSmall = new KDCustomHTMLView
      cssClass    : "add-vm-box selected"
      partial     :
        """
          <h3>Small <cite>1x</cite></h3>
          <ul>
            <li><strong>1</strong> CPU</li>
            <li><strong>5GB</strong> RAM</li>
            <li><strong>1TB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Large <cite>2x</cite></h3>
          <ul>
            <li><strong>2</strong> CPU</li>
            <li><strong>5GB</strong> RAM</li>
            <li><strong>1TB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmExtraLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Extra Large <cite>3x</cite></h3>
          <ul>
            <li><strong>3</strong> CPU</li>
            <li><strong>5GB</strong> RAM</li>
            <li><strong>1TB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView comingSoonTitle = new KDCustomHTMLView
      cssClass     : "coming-soon-title"
      tagName      : "h5"
      partial      : "Coming soon..."

    # @addVmModal = new KDModalView
    #   title        : 'Add Virtual Machine'
    #   cssClass     : 'add-vm-modal'
    #   view         : addVmSelection
    #   overlay      : yes
    #   width        : 786
    #   buttons      :
    #     create     :
    #       title    : "Create"
    #       style    : "modal-clean-green"

    @addDomainModal = new KDModalView
      title          : "Add Domain"
      view           : new DomainCreateForm
      width          : 700
      overlay        : yes
      buttons        :
        createButton :
          title      : "Create"
          style      : "modal-clean-green"

  refreshContainers:->
    # After Domains and Machines container load finished
    # Call updateConnections to draw lines between corresponding objects
    @scene.whenItemsLoadedFor @_containers, =>
      @scene.updateConnections()
