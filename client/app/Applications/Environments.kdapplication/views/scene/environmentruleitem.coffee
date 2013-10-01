class EnvironmentRuleItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'rule'
    options.joints             = ['right']
    options.allowedConnections =
      EnvironmentDomainItem : ['left']

    super options, data
