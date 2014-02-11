class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'domain'
    options.joints             = ['left','right']
    options.staticJoints       = ['left']

    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']

    super options, data

  confirmDestroy : ->
    @deletionModal = new DomainDeletionModal {}, @getData().domain
    @deletionModal.on "domainRemoved", @bound 'destroy'
