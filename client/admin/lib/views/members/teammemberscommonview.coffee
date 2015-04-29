kd                   = require 'kd'
KDView               = kd.View
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.noItemFoundWidget or= new KDCustomHTMLView
    options.listViewItemClass or= KDListItemView

    super options, data

    @createListController()
    @listMembers()


  createListController: ->

    { listViewItemClass, noItemFoundWidget } = @getOptions

    @listController       = new KDListViewController
      itemClass           : listViewItemClass
      noItemFoundWidget   : noItemFoundWidget
      startWithLazyLoader : yes
      lazyLoadThreshold   : .90
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()


  ###*
    This method needs to be implemented in subclasses.

    @abstract
  ###
  listMembers: -> throw new Error 'Method needs to be implemented in subclasses'
