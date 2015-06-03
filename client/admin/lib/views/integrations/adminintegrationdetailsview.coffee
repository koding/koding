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
        partial  : applyMarkdown instructions
        cssClass : 'has-markdown instructions'
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