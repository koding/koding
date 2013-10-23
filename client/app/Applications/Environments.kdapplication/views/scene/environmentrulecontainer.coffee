class EnvironmentRuleContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.itemClass = EnvironmentRuleItem
    options.title     = 'Rules'
    super options, data

  addItem:->
    super
    log "Added to rules:", arguments

  loadItems:->
    super

    dummyRules = [
      {
        title: "Allow Turkey",
        description: "allow from 5.2.80.0/21"
      },
      {
        title: "Block China",
        description: "deny from 65.19.146.2 220.248.0.0/14"
      },
      {
        title: "Allow Gokmen's Machine",
        description: "allow from 1.2.3.4"
      }
    ]

    @addItem rule for rule in dummyRules
    @emit "DataLoaded"
    log "Rules loaded.", @
