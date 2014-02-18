class EnvironmentExtraContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'extras'
    options.itemClass = EnvironmentExtraItem
    options.title     = 'Shared Storage'
    super options, data

    @on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more resource will be available soon."

  loadItems:->
    super

    dummyAdditionals = [
      {
        title: "Shared Space",
        description: "additional "
      }
    ]

    @addItem addition for addition in dummyAdditionals
    @emit "DataLoaded"