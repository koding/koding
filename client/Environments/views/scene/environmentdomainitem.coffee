class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'domain'
    options.joints             = ['right']

    options.allowedConnections =
      EnvironmentMachineItem   : ['left']

    super options, data

  confirmDestroy : ->
    @deletionModal = new DomainDeletionModal {}, @getData().domain
    @deletionModal.on "domainRemoved", @bound 'destroy'
