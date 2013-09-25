class EnvironmentDomainItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.joints             = ['right']
    options.cssClass           = 'domain'
    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']

    super options, data

  confirmDestroy : ->
    @deletionModal = new DomainDeletionModal {}, @getData().domain
    @deletionModal.on "domainRemoved", @bound 'destroy'

  contextMenuItems : ->
    items =
      'Edit Properties'       :
        action                : 'editProperties'
      'Focus On This Domain'  :
        action                : 'focus'
      'Unfocus'               :
        action                : 'unfocus'
      'Edit Bindings'         :
        separator             : yes
        action                : 'editBindings'
      'Color Tag'             :
        separator             : yes
        children              :
          customView          : @colorSelection = new ColorSelection
            selectedColor     : @getOption 'colorTag'
      'Rename'                :
        action                : 'rename'
      'Combine Into Group'    :
        action                : 'combine'
      'Delete'                :
        separator             : yes
        action                : 'delete'
      'Create New Domain'     :
        action                : 'createItem'
      'Create Empty Group'    :
        action                : 'createGroup'

    return items