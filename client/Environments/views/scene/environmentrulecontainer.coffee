class EnvironmentRuleContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "rules", ->

    new Promise (resolve, reject) ->
      KD.remote.api.JProxyFilter.fetch {}, (err, filters) ->
        if err or not filters or filters.length is 0
          warn "Failed to fetch domains", err  if err
          return resolve []

        filter.title = filter.name  for filter in filters
        resolve filters

  constructor: (options = {}, data) ->

    options.cssClass  = "firewall"
    options.itemClass = EnvironmentRuleItem
    options.title     = "firewall rules"

    super options, data

    @on "PlusButtonClicked", =>
      modal = new AddFirewallRuleModal
      modal.once "NewRuleAdded", (filter) =>
        @addItem
          title       : filter.name
          description : $.timeago filter.createdAt
          activated   : yes
          filter      : filter

        @emit "itemAdded"
        modal.destroy()
