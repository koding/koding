class IDE.WorkspaceTabView extends JView

  constructor: (options = {}, data) ->

    options.cssClass       = KD.utils.curry 'ws-tabview', options.cssClass
    options.addPlusHandle ?= yes

    super options, data

    @createTabHolderView()
    @createTabView()

  createTabHolderView: ->
    @holderView     = new ApplicationTabHandleHolder
      addPlusHandle : @getOption 'addPlusHandle'
      delegate      : this

  createTabView: ->
    TabViewClass = @getOption('tabViewClass') or ApplicationTabView
    @tabView     = new TabViewClass
      tabHandleContainer        : @holderView
      closeAppWhenAllTabsClosed : no

  pistachio: ->
    """
      {{> @holderView}}
      {{> @tabView}}
    """
