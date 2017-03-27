module.exports =

  actions : require './actions'
  getters : require './getters'
  stores  : [
    require './stores/stacksstore'
    require './stores/machinesstore'
    require './stores/sharedmachinelistitemsstore'
    require './stores/connectedmanagedmachinestore'
    require './stores/activemachinestore'
    require './stores/activeinvitationmachineidstore'
    require './stores/activeleavingsharedmachineidstore'
    require './stores/differentstackresourcesstore'
    require './stores/activestackstore'
    require './stores/teamstacktemplatesstore'
    require './stores/privatestacktemplatesstore'
    require './stores/selectedtemplateidstore'
    require './stores/expandedmachinelabelstore'
  ]

  register: (reactor) -> reactor.registerStores @stores
