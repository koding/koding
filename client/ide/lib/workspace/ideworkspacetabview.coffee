kd                          = require 'kd'

ApplicationTabHandleHolder  = require 'app/commonviews/applicationview/applicationtabhandleholder'
ApplicationTabView          = require 'app/commonviews/applicationview/applicationtabview'


module.exports = class IDEWorkspaceTabView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass       = kd.utils.curry 'ws-tabview', options.cssClass
    options.addPlusHandle ?= yes

    super options, data

    @createTabHolderView()
    @createTabView()

  createTabHolderView: ->
    @holderView     = new ApplicationTabHandleHolder
      cssClass      : 'idetabhandle-holder'
      addPlusHandle : @getOption 'addPlusHandle'
      delegate      : this

  createTabView: ->
    TabViewClass = @getOption('tabViewClass') or ApplicationTabView
    @tabView     = new TabViewClass
      tabHandleContainer        : @holderView
      closeAppWhenAllTabsClosed : no

  pistachio: ->
    '''
      {{> @holderView}}
      {{> @tabView}}
    '''
