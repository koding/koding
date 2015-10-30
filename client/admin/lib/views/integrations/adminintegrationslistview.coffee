kd                       = require 'kd'
remote                   = require('app/remote').getInstance()
integrationHelpers       = require 'app/helpers/integration'
AdminIntegrationItemView = require './adminintegrationitemview'


module.exports = class AdminIntegrationsListView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass            = 'all-integrations'
    options.listItemClass     or= AdminIntegrationItemView
    options.fetcherMethodName or= 'list'

    super options, data

    @integrationType = @getOption 'integrationType'

    @createListController()
    @fetchIntegrations()

    @addSubView @subContentView = new kd.CustomScrollView


  createListController: ->

    @listController       = new kd.ListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : @getOptions().listItemClass
      useCustomScrollView : yes
      noItemFoundWidget   : new kd.CustomHTMLView
        cssClass          : 'hidden no-item-found'
        partial           : 'No integration available.'
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()


  fetchIntegrations: ->

    methodName = @getOption 'fetcherMethodName'

    integrationHelpers[methodName] (err, data) =>

      return @handleNoItem err  if err

      @listItems data


  refresh: ->

    @listController.removeAllItems()
    @listController.lazyLoader.show()
    @fetchIntegrations()


  listItems: (items) ->

    if not items or items.length is 0
      return @handleNoItem()

    for item in items
      item.integrationType = @integrationType
      listItem = @listController.addItem item

    @listController.lazyLoader.hide()


  handleNoItem: (err) ->

    kd.warn err  if err
    @listController.lazyLoader.hide()
    @listController.noItemView.show()
