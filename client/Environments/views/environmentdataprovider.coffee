class EnvironmentDataProvider

  @providers   = {}
  @addProvider = (label, promise)->
    @providers[label] = promise

  @log = ->
    log @providers

  @load = ->
    Promise.all (promise()  for provider, promise of @providers)

  @get = (callback)->
    @load().spread (rules, domains, vms, extras)->
      callback {rules, domains, vms, extras}
