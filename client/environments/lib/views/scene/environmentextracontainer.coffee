kd = require 'kd'
KDNotificationView = kd.NotificationView
EnvironmentContainer = require './environmentcontainer'
EnvironmentExtraItem = require './environmentextraitem'
Promise = require 'bluebird'
EnvironmentDataProvider = require './../environmentdataprovider'

module.exports = class EnvironmentExtraContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "extras", ->

    dummyAdditionals = [
      {
        title: "Shared Space",
        description: "additional"
      }
    ]

    new Promise (resolve, reject)->
      resolve dummyAdditionals

  constructor:(options={}, data)->
    options.cssClass  = 'extras'
    options.itemClass = EnvironmentExtraItem
    options.title     = 'shared storage'
    super options, data

    @on 'PlusButtonClicked', ->
      new KDNotificationView title: "Adding more resource will be available soon."
