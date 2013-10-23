class EnvironmentExtraItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'additional'
    options.joints             = ['left']
    options.allowedConnections =
      EnvironmentMachineItem : ['right']

    super options, data
