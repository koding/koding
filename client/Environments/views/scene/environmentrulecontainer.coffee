class EnvironmentRuleContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'firewall'
    options.itemClass = EnvironmentRuleItem
    options.title     = 'Firewall'
    super options, data

  loadItems:->
    super

    dummyRules = [
      {
        title: "Allow All",
        description: "allow from *"
      }
      {
        title: "Allow Only Me",
        description: "allow my requests"
      }
    ]

    @addItem rule for rule in dummyRules
    @emit "DataLoaded"
