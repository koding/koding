class EnvironmentExtraContainer extends EnvironmentContainer

  constructor:(options={}, data)->
    options.itemClass = EnvironmentExtraItem
    options.title     = 'Extras'
    super options, data

  loadItems:->
    super

    dummyAdditionals = [
      {
        title: "20 GB Extra Space",
        description: "additional 20 GB"
      },
      {
        title: "10 GB Extra Space",
        description: "additional 20 GB"
      },
      {
        title: "512 MB Extra Memory",
        description: "additional 512 MB Ram"
      },
      {
        title: "4 GB Extra Memory",
        description: "additional 4 GB Ram"
      }
    ]

    @addItem addition for addition in dummyAdditionals
    @emit "DataLoaded"