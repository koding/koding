class EnvironmentsMainScene extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'environment-content', options.cssClass
    super options, data

  viewAppended:->

    # Action Area for Domains
    @addSubView actionArea = new KDView cssClass : 'action-area'

    # Domain Creation form in actionArea
    actionArea.addSubView @domainCreateForm = new DomainCreationForm

    # Domain Creation form connections
    @domainCreateForm.on 'CloseClicked', =>
      @scene.unsetClass 'out'
      @scene.off "click"

    # Main scene for DIA
    @addSubView @scene = new EnvironmentScene

    # Domains Container
    domainsContainer = new EnvironmentDomainContainer
    @scene.addContainer domainsContainer
    domainsContainer.on "itemRemoved", @domainCreateForm.bound "updateDomains"

    # VMs / Machines Container
    machinesContainer = new EnvironmentMachineContainer
    @scene.addContainer machinesContainer

    @_containers = [domainsContainer, machinesContainer]
    for container in @_containers
      container.on 'DataLoaded', @scene.bound 'updateConnections'

    @refreshContainers()

    @domainCreateForm.on 'DomainSaved', domainsContainer.bound 'loadItems'
    KD.getSingleton("vmController").on 'VMListChanged', \
                                        @bound 'refreshContainers'

    # Plus button on domainsContainer opens up the action area
    domainsContainer.on 'PlusButtonClicked', =>
      return unless KD.isLoggedIn()
        new KDNotificationView title: "You need to login to add a new domain."

      return if machinesContainer.diaCount() is 0
        new KDNotificationView
          title: "You need to have at least one VM to manage domains."

      @scene.setClass 'out'
      @domainCreateForm.emit 'DomainNameShouldFocus'
      @utils.defer =>
        @scene.once 'click', => @domainCreateForm.emit 'CloseClicked'

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

  refreshContainers:->
    # After Domains and Machines container load finished
    # Call updateConnections to draw lines between corresponding objects
    @scene.whenItemsLoadedFor @_containers, =>
      @scene.updateConnections()
