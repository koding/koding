kd           = require 'kd'
JView        = require 'app/jview'
remote       = require('app/remote').getInstance()
KDSelectBox  = kd.SelectBox
KDButtonView = kd.ButtonView

module.exports = class AdminIntegrationSetupView extends JView

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

    data = @getData()
    options =
      integrationId : data.id
      channelId     : @channelSelect.getValue()

    kd.singletons.socialapi.integrations.create options, (err, response) =>
      return console.warn "couldnt create integration", err  if err

      data.token = response.token
      data.id = response.id
      data.integrationId = response.integrationId
      data.selectedChannel = response.channelId
      data.webhookUrl = "https://koding.com/api/integration/#{data.name}/#{data.token}"

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
