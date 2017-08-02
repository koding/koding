kd = require 'kd'

Encoder = require 'htmlencode'
StackTemplateEditorView = require 'stack-editor/editor/stacktemplateeditorview'

module.exports = class StackTemplatePageView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { stack, stackTemplate } = @getData()

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
      <div class="stack-template-page">
        <section class="main">
          <h2>Stack Template</h2>
          <p>A preview of the stack you are about to build</p>
          {{> @editorView}}
        </section>
        <footer>
          {{> @backButton}}
          {{> @nextButton}}
        </footer>
      </div>
    '''
