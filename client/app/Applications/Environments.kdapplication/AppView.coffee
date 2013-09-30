class EnvironmentsMainView extends JView

  constructor:->
    super cssClass : 'environment-content'

  viewAppended:->

    # Action Area for Domains
    @addSubView actionArea = new KDView cssClass : 'action-area'

    # Domain Creation form in actionArea
    actionArea.addSubView domainCreateForm = new DomainCreationForm

    # Domain Creation form connections
    domainCreateForm.on 'CloseClicked', =>
      @scene.unsetClass 'out'
      @scene.off "click"

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    # Domains Container
    domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer domainsContainer
    domainsContainer.on "itemRemoved", domainCreateForm.bound "updateDomains"

    # VMs / Machines Container
    machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer machinesContainer

    # After Domains and Machines container load finished
    # Call updateConnections to draw lines between corresponding objects
    @scene.whenItemsLoadedFor [domainsContainer, machinesContainer], =>
      @scene.updateConnections()
      domainsContainer.on  "DataLoaded", @scene.bound 'updateConnections'
      machinesContainer.on "DataLoaded", @scene.bound 'updateConnections'

    domainCreateForm.on 'DomainSaved', domainsContainer.bound 'loadItems'

    # Plus button on domainsContainer opens up the action area
    domainsContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      @scene.setClass 'out'
      domainCreateForm.emit 'DomainNameShouldFocus'
      @utils.defer =>
        @scene.once 'click', -> domainCreateForm.emit 'CloseClicked'

    vmController = KD.getSingleton 'vmController'

    vmController.on "VMPlansFetchStart", =>
      machinesContainer.showLoader()

    vmController.on "VMPlansFetchEnd", =>
      machinesContainer.hideLoader()

    # Plus button on machinesContainer uses the vmController
    machinesContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView
          title: "You need to login to create a new machine."

      vmController.createNewVM()
