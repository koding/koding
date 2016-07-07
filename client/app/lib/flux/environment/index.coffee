module.exports =

  actions : require './actions'
  getters : require './getters'
  stores  : [
    require './stores/stacksstore'
    require './stores/machinesstore'
    require './stores/workspacesstore'
    require './stores/ownmachinesstore'
    require './stores/sharedmachinesstore'
    require './stores/sharedmachinelistitemsstore'
    require './stores/machinesworkspacesstore'
    require './stores/collaborationmachinesstore'
    require './stores/addworkspaceviewstore'
    require './stores/activeworkspacestore'
    require './stores/deleteworkspacewidgetstore'
    require './stores/connectedmanagedmachinestore'
    require './stores/activemachinestore'
    require './stores/activeinvitationmachineidstore'
    require './stores/activeleavingsharedmachineidstore'
    require './stores/differentstackresourcesstore'
    require './stores/activestackstore'
    require './stores/teamstacktemplatesstore'
    require './stores/privatestacktemplatesstore'
    require './stores/selectedtemplateidstore'
  ]

  register: (reactor) -> reactor.registerStores @stores
