JView                       = require 'app/jview'
integrationHelpers          = require 'app/helpers/integration'
AdminIntegrationSetupView   = require './adminintegrationsetupview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'

DUMMY_DATA = {
  "channels": [
    {
      "name": "#public",
      "id": "6024983560752988161"
    }
  ],
  "id": "2",
  "integration": {
    "id": "3",
    "name": "travis",
    "title": "Travis CI",
    "summary": "Hosted software build services.",
    "iconPath": "https://koding-cdn.s3.amazonaws.com/temp-images/travisci.png",
    "description": "Travis CI is a continuous integration platform that takes care of running your software tests and deploying your apps. This integration will allow your team to receive notifications in Koding for normal branch builds, and for pull requests, as well.",
    "instructions": "",
    "typeConstant": "incoming",
    "settings": null,
    "createdAt": "2015-07-09T22:13:52.411093Z",
    "updatedAt": "2015-07-09T22:13:52.411093Z"
  },
  "token": "028e28f2-d19e-475a-5d93-507959cfeed0",
  "createdAt": "2015-07-11T01:06:42.427055Z",
  "updatedAt": "2015-07-11T01:06:42.427055Z",
  "description": "Hosted software build services.",
  "integrationId": "3",
  "selectedChannel": "6024983560752988161",
  "webhookUrl": "https://koding-acetz.ngrok.com/api/integration/travis/028e28f2-d19e-475a-5d93-507959cfeed0",
  "integrationType": "configured",
  "isDisabled": false,
  "selectedEvents": [],
  "repositories": []
}

module.exports = class AdminIntegrationParentView extends JView


  handleIdentifier: (identifier, action) ->

    @identifier = identifier

    @mainView?.destroy()

    if action is 'add' then @handleAdd() else @handleConfigure()


  handleAdd: ->

    integrationHelpers.find @identifier, (err, data) =>
      @addSubView @mainView = new AdminIntegrationSetupView {}, data


  handleConfigure: ->

    @addSubView @mainView = new AdminIntegrationDetailsView {}, DUMMY_DATA
