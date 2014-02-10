class EnvironmentDomainContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'domains'
    options.itemClass = EnvironmentDomainItem
    options.title     = 'Domains'
    super options, data

  loadItems:->

    KD.whoami().fetchDomains (err, domains)=>
      if err or domains.length is 0
        @emit "DataLoaded"
        return warn "Failed to fetch domains", err  if err

      addedCount = 0

      KD.singletons.vmController.fetchGroupVMs yes, (err, vms)=>

        @removeAllItems()

        domains.forEach (domain)=>

          if domain
            @addItem
              title       : domain.domain
              description : $.timeago domain.createdAt
              activated   : yes
              aliases     : domain.hostnameAlias
              domain      : domain

          addedCount++

          if addedCount is domains.length
            @emit "DataLoaded"
