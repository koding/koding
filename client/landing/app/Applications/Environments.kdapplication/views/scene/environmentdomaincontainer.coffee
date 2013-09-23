class EnvironmentDomainContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.itemClass = EnvironmentDomainItem
    options.title     = 'Domains'
    super options, data

  loadItems:->

    KD.whoami().fetchDomains (err, domains)=>
      if err
        @emit "DataLoaded"
        return warn "Failed to fetch domains", err
      addedCount = 0
      domains.forEach (domain)=>
        @addItem
          title       : domain.domain
          description : $.timeago domain.createdAt
          activated   : yes
          aliases     : domain.hostnameAlias
        addedCount++
        @emit "DataLoaded"  if addedCount is domains.length