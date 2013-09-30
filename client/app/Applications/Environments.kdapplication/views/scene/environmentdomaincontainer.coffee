class EnvironmentDomainContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.itemClass = EnvironmentDomainItem
    options.title     = 'Domains'
    super options, data

  loadItems:->

    KD.whoami().fetchDomains (err, domains)=>
      if err or domains.length is 0
        @emit "DataLoaded"
        return warn "Failed to fetch domains", err  if err
      addedCount = 0
      @removeAllItems()

      domains.forEach (domain)=>
        @addItem
          title       : domain.domain
          description : $.timeago domain.createdAt
          activated   : yes
          aliases     : domain.hostnameAlias
          domain      : domain
        addedCount++
        @emit "DataLoaded"  if addedCount is domains.length