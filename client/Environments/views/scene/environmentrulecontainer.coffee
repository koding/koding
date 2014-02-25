class EnvironmentRuleContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "rules", ->

    dummyRules = [
      {
        title: "Allow All",
        description: "allow from *"
      }
    ]

    new Promise (resolve, reject)->
      resolve dummyRules

  constructor:(options={}, data)->

    options.cssClass  = 'firewall'
    options.itemClass = EnvironmentRuleItem
    options.title     = 'firewall rules'

    super options, data

    @on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more rules will be available soon."
