class EnvironmentDomainItem extends EnvironmentItem
  constructor:(options={}, data)->
    options.joints             = ['left', 'right']
    options.cssClass           = 'domain'
    options.kind               = 'Domain'
    options.allowedConnections =
      EnvironmentRuleItem    : ['right']
      EnvironmentMachineItem : ['left']
    super options, data
