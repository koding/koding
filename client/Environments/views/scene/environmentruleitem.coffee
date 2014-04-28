class EnvironmentRuleItem extends EnvironmentItem

  constructor: (options = {}, data) ->

    options.cssClass           = 'rule'
    options.joints             = ['right']
    options.allowedConnections =
      EnvironmentDomainItem    : ['left']

    super options, data

  contextMenuItems: ->
    colorSelection = new ColorSelection
      selectedColor : @getOption 'colorTag'

    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items         =
      Edit        :
        disabled  : KD.isGuest()
        action    : 'edit'
      Delete      :
        disabled  : KD.isGuest()
        action    : 'delete'
        separator : yes
      customView  : colorSelection

    return items

