class EnvironmentMachineItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['left']
    options.cssClass           = 'machine'
    options.kind               = 'Machine'
    options.allowedConnections =
      EnvironmentDomainItem : ['right']
    super options, data
    @usage = new KDProgressBarView

  confirmDestroy : ->
    vmController = KD.getSingleton 'vmController'
    vmController.remove @getData().title

  viewAppended:->
    super
    @usage.updateBar @getData().usage, '%', ''

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

  pistachio:->
    """
      <div class='details'>
        {h3{#(title)}}
        {{> @usage}}
      </div>
    """