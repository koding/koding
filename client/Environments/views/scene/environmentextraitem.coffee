class EnvironmentExtraItem extends EnvironmentItem

  constructor:(options={}, data)->

    options.cssClass           = 'extras'
    options.joints             = ['left']
    options.staticJoints       = ['left']
    options.allowedConnections =
      EnvironmentMachineItem : ['right']

    super options, data

  contextMenu:-> no