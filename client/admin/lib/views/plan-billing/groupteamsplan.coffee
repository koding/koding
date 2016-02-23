kd                    = require 'kd'
KDView                = kd.View
GroupPlanItemView     = require './groupplanitemview'
KDListViewController  = kd.ListViewController


module.exports = class GroupTeamsPlan extends KDView


  constructor: (options = {}, data) ->

    options.listItemClass     or= GroupPlanItemView
    options.fetcherMethodName or= 'list'

    super options, data

    @createListController()
    @fetchPlans()


  createListController: ->

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : @getOptions().listItemClass
      useCustomScrollView : yes
      noItemFoundWidget   : new kd.CustomHTMLView
        cssClass          : 'hidden no-item-found'
        partial           : 'No plan available.'
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()

    @listController.on 'AllItemsAddedToList', => @listController.lazyLoader.hide()


  fetchPlans: ->

    { computeController } = kd.singletons

    computeController.fetchTeamPlans (plans) =>

      Object.keys(plans).forEach (key) =>

        plan      = plans[key]
        plan.name = key

        @listController.addItem plan
