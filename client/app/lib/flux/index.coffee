module.exports =
  actions:
    user: require './actions/user'
  stores: [
    require './stores/usersstore'
    require './stores/loggedinuseremailstore'
    require './stores/testsuitesfailurestore'
  ]

  register: (reactor) ->
    reactor.registerStores @stores

    PaymentFlux = require 'app/flux/payment'
    PaymentFlux(reactor)

    SidebarFlux = require 'app/flux/sidebar'
    SidebarFlux.register reactor

    SocialApiFlux = require 'app/flux/socialapi'
    SocialApiFlux.register reactor

