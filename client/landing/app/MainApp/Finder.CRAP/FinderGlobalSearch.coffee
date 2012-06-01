
class FinderGlobalSearch extends KDModalView
  search: (term, callback) ->
    @inProcess yes
    @getDelegate().command().searchFile {pathToDir: '/', regexp: "*#{term}*", caseSensitive: no}, (error, result) =>
      @inProcess no
      callback error, result
    
  viewAppended: ->
    @setHeight 'auto'
    form    = new KDFormView callback: =>
      @search @input.inputGetValue(), (error, results) =>
        _results = for path in results.found
          item = FS.create
            path: path
            name: path.split('/').pop()
        @drawResult _results, results
      
    label           = new KDLabelView title: 'Find'
    @_inProcess     = new KDLabelView title: 'In process...'
    @input          = new GlobalSearchInput name: 'search', callback: ->
      form.$().submit()
    @input.on 'go.down', =>
      @selectNext()
      
    @input.on 'go.up', ->
      @selectPrevious()
      
    @input.on 'open', ->
      log 'open'
          
    form.addSubView label
    form.addSubView @_inProcess
    form.addSubView @input
    # form.addSubView btn
    @searchResultController = new SearchResultItemsController {subItemClass: FinderSearchResultItem}, {items: []}
    @resultContainer        = new SearchResultItemsView
    @searchResultController.setView
      
    @addSubView form
    @addSubView @resultContainer
    @inProcess no
    
  selectNext: ->        
    log '+', @resultContainer
    
  selectPrevious: ->
      
  inProcess: (inProcess) ->
    if inProcess
      @_inProcess.$().show()
    else
      @_inProcess.$().hide()
      
  show: ->
    if @options.fx
      @setClass "active"
    else
      @getDomElement().show()
    
  hide: ->
    if @options.fx
      @unsetClass "active"
    else
      @getDomElement().hide()
    
  destroy: ->
    @hide()
      
  drawResult: (files, rawResult) ->
    log 'drawing resutls', files, rawResult
    @searchResultController.removeAllItems()
    @searchResultController.instantiateItems files, yes

    # @resultContainer.addListItem item = new FinderSearchResultItem {delegate: @}, {file}
    # do (item) =>
    #   item.listenTo
    #     KDEventTypes: 'OpenFile'
    #     listenedToInstance: item
    #     callback: =>
    #       # finderItem = @getDelegate().itemWithPath item.getData().file.path
    #       # log 'finderitem', finderItem, item.getData().file
    #       # log 'click', @getDelegate(), item.getData().file.path
    #       @getDelegate().openFile file: item.getData().file
      
      
  addSubView: (view) ->
    super view, '.kdmodal-content'
  