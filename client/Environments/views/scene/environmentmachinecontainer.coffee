class EnvironmentMachineContainer extends EnvironmentContainer

  # EnvironmentDataProvider.addProvider "vms", ->

  #   new Promise (resolve, reject)->

  #     KD.remote.api.ComputeProvider.fetchExisting
  #       provider : "koding"
  #     , (err, vms)->

  #       log "vms", vms
  #       if err or vms.length is 0
  #         warn "Failed to fetch VMs", err  if err
  #         return resolve []

  #       resolve vms

  constructor:(options={}, data)->

    options      =
      title      : 'virtual machines'
      cssClass   : 'machines'
      itemClass  : EnvironmentMachineItem
      itemHeight : 55

    super options, data

    @on 'PlusButtonClicked', =>
      ComputeController.UI.showProvidersModal @getData()

  # loadItems:->

  #   new Promise (resolve, reject)=>

  #     vmc = KD.getSingleton 'vmController'

  #     {entryPoint} = KD.config
  #     cmd = if entryPoint then 'fetchGroupVMs' else 'fetchVmNames'

  #     vmc.fetchGroupVMs yes, (err, vms)=>

  #       @removeAllItems()

  #       if err or vms.length is 0
  #         warn "Failed to fetch VMs", err  if err
  #         return resolve()

  #       vms.forEach (vm, index)=>
  #         {hostnameAlias} = vm
  #         @addItem {
  #           title     : hostnameAlias
  #           cpuUsage  : KD.utils.getRandomNumber 100
  #           memUsage  : KD.utils.getRandomNumber 100
  #           activated : yes
  #           hostnameAlias
  #           vm
  #         }

  #         if index is vms.length - 1 then resolve()
