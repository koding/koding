class EnvironmentRuleContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'firewall'
    options.itemClass = EnvironmentRuleItem
    options.title     = 'firewall rules'
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

    new Promise (resolve, reject)=>
      @addItem rule for rule in dummyRules
      resolve()
