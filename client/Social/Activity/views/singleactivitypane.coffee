class SingleActivityPane extends ActivityPane

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'single-activity', options.cssClass

    super options, data


  viewAppended: ->

    @tabView.tabHandleContainer.destroy()

    @addSubView @scrollView
    @scrollView.wrapper.addSubView @tabView

