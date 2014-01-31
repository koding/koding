class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

  viewAppended:->

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

    if KD.checkFlag 'nostradamus'
      # Rules Container
      rulesContainer = new EnvironmentRuleContainer
      @scene.addContainer rulesContainer
      # rulesContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # Domains Container
    @domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer @domainsContainer
    @domainsContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # VMs / Machines Container
    @machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer @machinesContainer

    @_containers = [@machinesContainer, @domainsContainer]

    if KD.checkFlag 'nostradamus'
      # Rules Container
      extrasContainer = new EnvironmentExtraContainer
      @scene.addContainer extrasContainer
      @_containers = @_containers.concat [rulesContainer, extrasContainer]

    for container in @_containers
      container.on 'DataLoaded', @scene.bound 'updateConnections'

    @refreshContainers()


    @addSubView @resourcesContainer = new ResourcesContainer

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


  refreshContainers:->
    # After Domains and Machines container load finished
    # Call updateConnections to draw lines between corresponding objects
    @scene.whenItemsLoadedFor @_containers, =>
      @scene.updateConnections()
