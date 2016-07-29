kd = require 'kd'
JView = require 'app/jview'
Encoder = require 'htmlencode'
BuildStackHeaderView = require './buildstackheaderview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'
StackTemplateEditorView = require 'stacks/views/stacks/editors/stacktemplateeditorview'

module.exports = class StackTemplatePageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    { stack, stackTemplate } = @getData()

    @header = new BuildStackHeaderView {}, stack

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.Instructions

    { template: { rawContent } } = stackTemplate
    @editorView = new StackTemplateEditorView
      delegate    : this
      content     : Encoder.htmlDecode rawContent
      contentType : 'yaml'
      readOnly    : yes
      showHelpContent : no
    { ace }   = @editorView.aceView
    ace.ready => @editorView.resize()

    @backButton = new kd.ButtonView
      title    : 'Back to Read Me'
      cssClass : 'GenericButton secondary'
      callback : @lazyBound 'emit', 'ReadmeRequested'

    @nextButton = new kd.ButtonView
      title    : 'Next'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'NextPageRequested'


  pistachio: ->

    '''
      <div class="build-stack-flow stack-template-page">
        {{> @header}}
        {{> @progressPane}}
        <section class="main">
          <h2>Stack Template</h2>
          <p>&nbsp;</p>
          {{> @editorView}}
        </section>
        <footer>
          {{> @backButton}}
          {{> @nextButton}}
        </footer>
      </div>
    '''
