class FormWorkflowModal extends KDModalView

  viewAppended: ->

    @setClass 'workflow-modal'

    nav = new BidirectionalNavigation

    @addSubView nav, '.kdmodal-title'

    { view: workflow } = @getOptions()

    nav.on 'Back', workflow.bound 'back'
    nav.on 'Next', workflow.bound 'next'
