module.exports =

  actions : require './actions'
  getters : require './getters'
  stores  : [
    require './stores/stacksstore'
    require './stores/machinesstore'
    require './stores/workspacesstore'
    require './stores/ownmachinesstore'
    require './stores/sharedmachinesstore'
    require './stores/machinesworkspacesstore'
    require './stores/collaborationmachinesstore'
    require './stores/addworkspaceviewstore'
    require './stores/activeworkspacestore'
    require './stores/deleteworkspacewidgetstore'
  ]

  register: (reactor) -> reactor.registerStores @stores