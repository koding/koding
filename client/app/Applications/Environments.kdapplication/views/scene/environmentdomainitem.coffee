class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.joints             = ['left', 'right']
    options.cssClass           = 'domain'
    options.kind               = 'Domain'

    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']

    super options, data

  confirmDestroy:->
    @deletionModal = new DomainDeletionModal {}, @getData().domain
    @deletionModal.on "domainRemoved", @bound 'destroy'