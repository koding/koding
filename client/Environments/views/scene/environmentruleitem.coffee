class EnvironmentRuleItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'rule'
    options.joints             = ['right']
    options.staticJoints       = ['right']
    options.allowedConnections =
      EnvironmentDomainItem : ['left']

    super options, data

  contextMenu:-> no