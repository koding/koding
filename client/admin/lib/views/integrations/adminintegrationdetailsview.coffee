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
          <p class='subtitle'>Here are the steps necessary to add the #{data.title} integration.</p>
          <hr />
        """
      @instructionsView.addSubView new KDCustomHTMLView
        partial  : applyMarkdown instructions
    else
      @instructionsView = new KDCustomHTMLView cssClass: 'hidden'

    items = ({ title: channel.name, value: channel.id } for channel in data.channels)

    @settingsForm       = new KDFormViewWithFields
      cssClass          : 'AppModal-form details-form'
      fields            :
        channels        :
          type          : 'select'
          label         : '<p>Post to Channel</p><span>Which channel should we post exceptions to?</span>'
          selectOptions : items
          defaultValue  : data.selectedChannel
        url             :
          type          : 'input'
          cssClass      : 'text'
          label         : "<p>Webhook URL</p><span>When setting up this integration, this is the URL that you will paste into #{data.title}.</span>"
          defaultValue  : data.webhookUrl
          attributes    : readonly: 'readonly'
        label           :
          type          : 'input'
          cssClass      : 'text'
          label         : '<p>Descriptive Label</p><span>Use this label to provide extra context in your list of integrations (optional).</span>'
          defaultValue  : data.summary
        name            :
          type          : 'input'
          cssClass      : 'text'
          label         : '<p>Customize Name</p><span>Choose the username that this integration will post as.</span>'
          defaultValue  : data.title
      buttons           :
        Save            :
          title         : 'Save Integration'
          type          : 'submit'
          cssClass      : 'solid green medium save'
          loader        : yes
        Cancel          :
          title         : 'Cancel'
          cssClass      : 'solid green medium red'
          callback      : => @emit 'IntegrationCancelled'

      callback          : (formData) =>
        data = @getData()
        { name, label, channels } = formData
        options =
          id          : data.id
          channelId   : channels

        if label isnt data.summary
          options.description = label

        if name isnt data.title
          options.settings = customName : name

        kd.singletons.socialapi.integrations.update options, (err) =>
          return kd.warn err  if err

          @settingsForm.buttons.Save.hideLoader()
          @emit 'NewIntegrationSaved'


  pistachio: ->

    { title, description, summary, iconPath } = @getData()

    return """
      <header class="integration-view">
        <img src="#{iconPath}" />
        {p{ #(title)}}
        {{ #(summary)}}
      </header>
      {section.description{ #(description)}}
      {{> @instructionsView}}
      <section class="settings">
        <h4 class='title'>Integration Settings</h4>
        <hr />
        {{> @settingsForm}}
      </section>
    """
