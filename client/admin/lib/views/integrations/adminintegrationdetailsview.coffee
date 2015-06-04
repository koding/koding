kd                   = require 'kd'
JView                = require 'app/jview'
applyMarkdown        = require 'app/util/applyMarkdown'
KDCustomHTMLView     = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields


module.exports = class AdminIntegrationDetailsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-details'

    super options, data

    { instructions } = data

    if instructions
      @instructionsView = new KDCustomHTMLView
        tagName  : 'section'
        cssClass : 'has-markdown instructions'
        partial  : """
          <h4 class='title'>Setup Instructions</h4>
          <p class='subtitle'>Here are the steps necessary to add the #{data.name} integration.</p>
          <hr />
        """
      @instructionsView.addSubView new KDCustomHTMLView
        partial  : applyMarkdown instructions
    else
      @instructionsView = new KDCustomHTMLView cssClass: 'hidden'

    items = ({ title: channel.name, value: channel.id } for channel in data.channels)

    @settingsForm       = new KDFormViewWithFields
      cssClass          : 'AppModal-form'
      fields            :
        channels        :
          type          : 'select'
          label         : '<p>Post to Channel</p><span>Which channel should we post exceptions to?</span>'
          selectOptions : items
          defaultValue  : data.selectedChannel
        url             :
          type          : 'input'
          label         : '<p>Webhook URL</p><span>When setting up this integration, this is the URL that you will paste into Airbrake.</span>'
          defaultValue  : data.webhookUrl
        label           :
          type          : 'input'
          label         : '<p>Descriptive Label</p><span>Use this label to provide extra context in your list of integrations (optional).</span>'
          defaultValue  : data.summary
        name            :
          type          : 'input'
          label         : '<p>Customize Name</p><span>Choose the username that this integration will post as.</span>'
          defaultValue  : data.name
      buttons           :
        Save            :
          title         : 'Save Integration'
          cssClass      : 'solid green medium'


  pistachio: ->

    { name, desc, summary, logo } = @getData()

    return """
      <header class="integration-view">
        <img src="#{logo}" />
        {p{ #(name)}}
        {{ #(summary)}}
      </header>
      {section.description{ #(desc)}}
      {{> @instructionsView}}
      <section class="settings">
        <h4 class='title'>Integration Settings</h4>
        <hr />
        {{> @settingsForm}}
      </section>
    """