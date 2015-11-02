kd                 = require 'kd'
globals            = require 'globals'
JView              = require 'app/jview'
remote             = require('app/remote').getInstance()
KDSelectBox        = kd.SelectBox
KDButtonView       = kd.ButtonView
integrationHelpers = require 'app/helpers/integration'


module.exports = class AdminIntegrationSetupView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-channels'

    super options, data

    selectOptions = []

    for channel in data.channels
      continue  if channel.name is '#public'
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
      callback : -> kd.singletons.router.handleRoute '/Admin/Integrations'


  setIntegration: ->

    options =
      integrationId : @getData().id
      channelId     : @channelSelect.getValue()

    integrationHelpers.create options, (err, response) =>
      return console.warn "couldnt create integration", err  if err

      @emit 'NewIntegrationAdded'
      kd.singletons.router.handleRoute "/Admin/Integrations/Configure/#{response.id}"


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
