kd               = require 'kd'
JView            = require 'app/jview'
applyMarkdown    = require 'app/util/applyMarkdown'
KDCustomHTMLView = kd.CustomHTMLView

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
    """