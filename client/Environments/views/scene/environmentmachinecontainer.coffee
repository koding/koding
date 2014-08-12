class EnvironmentMachineContainer extends EnvironmentContainer

  constructor:(options={}, data)->

    options      =
      title      : 'virtual machines'
      cssClass   : 'machines'
      itemClass  : EnvironmentMachineItem
      itemHeight : 55

    super options, data

    @on 'PlusButtonClicked', =>
      ComputeController.UI.showProvidersModal @getData()
