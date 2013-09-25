class EnvironmentMachineContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.itemClass = EnvironmentMachineItem
    options.title     = 'Machines'
    super options, data

    vmController = KD.getSingleton('vmController')
    vmController.on 'VMListChanged', =>
      @utils.defer => @refreshItems()

  refreshItems:->
    log "refreshItems"
    for key, dia of @dias
      dia.destroy()
    @loadItems()


  loadItems:->
    vmc = KD.getSingleton 'vmController'
    vmc.fetchVMs (err, vms)=>
      if err
        @emit "DataLoaded"
        return warn "Failed to fetch VMs", err
      addedCount = 0
      vms.forEach (vm)=>
        @addItem
          title     : vm
          usage     : KD.utils.getRandomNumber 100
          activated : yes
        addedCount++
        @emit "DataLoaded"  if addedCount is vms.length