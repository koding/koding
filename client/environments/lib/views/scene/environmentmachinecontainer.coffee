EnvironmentContainer = require './environmentcontainer'
EnvironmentMachineItem = require './environmentmachineitem'
ComputeController = require 'app/providers/computecontroller'
ComputeController_UI = require 'app/providers/computecontroller.ui'
module.exports = class EnvironmentMachineContainer extends EnvironmentContainer

  constructor:(options={}, data)->

    options      =
      title      : 'virtual machines'
      cssClass   : 'machines'
      itemClass  : EnvironmentMachineItem
      itemHeight : 55

    super options, data

    @on 'PlusButtonClicked', =>
      ComputeController_UI.showProvidersModal @getData()
