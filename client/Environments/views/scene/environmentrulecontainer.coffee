class EnvironmentRuleContainer extends EnvironmentContainer

  # EnvironmentDataProvider.addProvider "rules", ->

  #   new Promise (resolve, reject) ->
  #     KD.remote.api.JProxyRestriction.some {}, {}, (err, restrictions) ->
  #       EnvironmentRuleContainer.restrictions = restrictions # TODO: Find a better way

  #       KD.remote.api.JProxyFilter.some {}, {}, (err, filters) ->
  #         if err or not filters or filters.length is 0
  #           warn "Failed to fetch filters", err  if err
  #           return resolve []

  #         filter.title = filter.name  for filter in filters
  #         resolve filters

  constructor: (options = {}, data) ->

    options     =
      title     : "firewall rules"
      cssClass  : "firewall"
      itemClass : EnvironmentRuleItem

    super options, data

    @on "PlusButtonClicked", =>

      modal = new AddFirewallRuleModal
      modal.once "NewRuleAdded", (rule) =>
        rule.title       = rule.name
        rule.description = $.timeago rule.createdAt
        rule.activated   = yes

        @addItem rule
        @emit "itemAdded"
        modal.destroy()
