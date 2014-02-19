class EnvironmentExtraContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.cssClass  = 'extras'
    options.itemClass = EnvironmentExtraItem
    options.title     = 'shared storages'
    super options, data

    @on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more resource will be available soon."

  loadItems:->
    super

    dummyAdditionals = [
      {
        title: "Shared Space",
        description: "additional"
      }
    ]

    new Promise (resolve, reject)=>
      @addItem addition for addition in dummyAdditionals
      resolve()