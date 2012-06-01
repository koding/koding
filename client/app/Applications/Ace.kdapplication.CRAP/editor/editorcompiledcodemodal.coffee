class CompiledCodeWindow extends KDModalView
  viewAppended: ->
    scrollView = new KDScrollView
    scrollView.setHeight @getOptions().height - 50 # what is that 50???
    preView    = new KDCustomHTMLView 'pre'

    preView.$().html @getOptions().code
    scrollView.addSubView preView
    @addSubView scrollView, '.kdmodal-content'
