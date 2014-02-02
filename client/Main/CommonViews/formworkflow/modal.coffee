class FormWorkflowModal extends KDModalView
  constructor:(options = {}, data = {})->
    options.showNav ?= yes

    super options, data


  viewAppended: ->
    { view: workflow } = @getOptions()
    @setClass 'workflow-modal'

    if @getOption 'showNav'
      nav = new BidirectionalNavigation

      @addSubView nav, '.kdmodal-title'

      nav.on 'Back', workflow.bound 'back'
      nav.on 'Next', workflow.bound 'next'
