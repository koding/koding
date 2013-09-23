class EnvironmentRuleItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['right']
    options.cssClass           = 'rule'
    options.kind               = 'Rule'
    options.allowedConnections =
      EnvironmentDomainItem : ['left']
    super options, data
