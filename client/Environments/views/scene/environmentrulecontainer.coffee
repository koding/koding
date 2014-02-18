class EnvironmentRuleContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'firewall'
    options.itemClass = EnvironmentRuleItem
    options.title     = 'Firewall'
    super options, data

    @on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more rules will be available soon."

  loadItems:->
    super

    dummyRules = [
      {
        title: "Allow All",
        description: "allow from *"
      }
    ]

    @addItem rule for rule in dummyRules
    @emit "DataLoaded"
