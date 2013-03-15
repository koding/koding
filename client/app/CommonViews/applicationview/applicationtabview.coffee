class ApplicationTabView extends KDTabView
  constructor: (options = {}, data) ->

    options.resizeTabHandles     = yes
    options.lastTabHandleMargin  = 40
    options.sortable             = yes

    super options, data

    appView = @getDelegate()

    @on 'PaneRemoved', =>
      appView.emit 'AllViewsClosed' if @panes.length is 0
      @tabHandleContainer.repositionPlusHandle @handles

    @on 'PaneAdded', => 
      @tabHandleContainer.repositionPlusHandle @handles
