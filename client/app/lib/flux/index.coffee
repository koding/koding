module.exports =
  actions:
    user: require './actions/user'
  stores: [
    require './stores/usersstore'
    require './stores/loggedinuseremailstore'
  ]

  register: (reactor) ->
    reactor.registerStores @stores

    SidebarFlux = require 'app/flux/sidebar'
    SidebarFlux.register reactor

    SocialApiFlux = require 'app/flux/socialapi'
    SocialApiFlux.register reactor
