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
      callback : @bound 'fetchIntegrationConfig'

    @cancelButton = new KDButtonView
      title    : 'Cancel'
      cssClass : 'solid red compact cancel'
      callback : @bound 'destroy'


  handleChannelSelect: ->


  fetchIntegrationConfig: ->


  pistachio: ->

    { name, desc, summary, logo } = @getData()

    return """
      <header class="integration-view">
        <img src="#{logo}" />
        <p>#{name}</p>
        <span>#{summary}</span>
      </header>
      <section class="description">#{desc}</section>
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
