class ContentDisplayScrollableView extends KDView

  constructor: (options = {}, data) ->
    
    options.type = options.contentDisplay.getOptions().type
    
    super options, data
    
    @listenWindowResize()
    
  
  viewAppended: ->
    
    @scrollView = new KDCustomScrollView
      lazyLoadThreshold : 100

    @scrollView.wrapper.addSubView @getOptions().contentDisplay
    
    @addSubView @scrollView
    
    @forwardEvent @scrollView.wrapper, 'LazyLoadThresholdReached'


  _windowDidResize: ->
    
    @getOptions().contentDisplay.setCss { minHeight : window.innerHeight }
    @scrollView.setHeight window.innerHeight