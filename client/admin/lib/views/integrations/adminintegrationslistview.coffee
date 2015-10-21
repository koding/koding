kd                          = require 'kd'
KDView                      = kd.View
remote                      = require('app/remote').getInstance()
KDCustomHTMLView            = kd.CustomHTMLView
KDCustomScrollView          = kd.CustomScrollView
KDListViewController        = kd.ListViewController
AdminIntegrationItemView    = require './adminintegrationitemview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'
integrationHelpers          = require 'app/helpers/integration'


module.exports = class AdminIntegrationsListView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass            = 'all-integrations'
    options.listItemClass     or= AdminIntegrationItemView
    options.fetcherMethodName or= 'list'

    super options, data

    @integrationType = @getOption 'integrationType'

    @createListController()
    @fetchIntegrations()

    @addSubView @subContentView = new KDCustomScrollView


  createListController: ->

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : @getOptions().listItemClass
      useCustomScrollView : yes
      noItemFoundWidget   : new KDCustomHTMLView
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
