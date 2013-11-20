class FormWorkflowModal extends KDModalView

  viewAppended: ->

    @setClass 'workflow-modal'

    nav = new BidirectionalNavigation

    @addSubView nav, '.kdmodal-title'

    { view: workflow } = @getOptions()

    nav.on 'Back', -> workflow.back()
    nav.on 'Next', -> workflow.next()
