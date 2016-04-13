module.exports =

  actions : require './actions'
  getters : require './getters'
  stores  : [
    require './stores/teamstore'
    require './stores/teammembersidstore'
    require './stores/teammembersrolestore'
    require './stores/teaminviteinputsstore'
    require './stores/teampendinginvitationstore'
    require './stores/teamsearchinputvaluestore'
  ]

  register: (reactor) -> reactor.registerStores @stores
