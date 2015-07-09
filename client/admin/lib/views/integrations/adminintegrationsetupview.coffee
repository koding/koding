kd                         = require 'kd'
globals                    = require 'globals'
JView                      = require 'app/jview'
remote                     = require('app/remote').getInstance()
KDSelectBox                = kd.SelectBox
KDButtonView               = kd.ButtonView
integrationHelpers         = require 'app/helpers/integration'
AdminIntegrationCommonView = require './adminintegrationcommonview'


module.exports = class AdminIntegrationSetupView extends AdminIntegrationCommonView

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-channels'

    super options, data

    selectOptions = []

    for channel in data.channels
      selectOptions.push title: channel.name, value: channel.id

    @channelSelect = new KDSelectBox { selectOptions }

    @addButton = new KDButtonView
      title    : "Add #{data.name} Integration"
      cssClass : 'solid green compact add'
      callback : @bound 'setIntegration'
      loader   : yes

    @cancelButton = new KDButtonView
      title    : 'Cancel'
      cssClass : 'solid red compact cancel'
      callback : @bound 'destroy'


  setIntegration: ->

    options =
      integrationId : @getData().id
      channelId     : @channelSelect.getValue()

    integrationHelpers.create options, (err, response) =>
      return console.warn "couldnt create integration", err  if err

      integration = @getData()

      data =
        id              : response.id
        integration     : @getData()
        token           : response.token
        integrationId   : response.integrationId
        selectedChannel : response.channelId
        channels        : integration.channels
        webhookUrl      : "#{globals.config.integration.url}/#{integration.name}/#{response.token}"

      if integration.settings?.events
        events = try JSON.parse integration.settings.events
        catch e then []
        data.settings = {events}

      delete integration.channels

      @destroy()
      @emit 'NewIntegrationAdded', data


  pistachio: ->

    { title, description, summary, iconPath } = @getData()

    return """
      <header class="integration-view">
        <img src="#{iconPath}" />
        {p{ #(title)}}
        {{ #(summary)}}
      </header>
      {section.description{ #(description)}}
      <section class="setup">
        <h4>Post to Channel</h4>
        <label>Start by choosing a channel where exceptions will be posted.</label>
        {{> @channelSelect}}
      </section>
      <section class="buttons">
        {{> @cancelButton}}
        {{> @addButton}}
      </section>
    """
