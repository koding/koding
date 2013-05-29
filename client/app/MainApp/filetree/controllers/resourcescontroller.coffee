class ResourcesController extends KDListViewController

  constructor:(options = {}, data)->
    options       = $.extend
      view        : new ResourcesView
      wrapper     : no
      scrollView  : no
    , options

    super options, data

    KD.singletons.vmController.fetchVMs (err, vms)=>
      @instantiateListItems vms  unless err
      @deselectAllItems()

    @getView().on 'DeselectAllItems', @bound 'deselectAllItems'

class ResourcesView extends KDListView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass  : 'resources-list'
      itemClass : ResourcesListItem
    , options

    super options, data

class ResourcesListItem extends KDListItemView

  constructor:(options = {}, vmName)->

    options.cssClass or= 'vm'
    super options, vmName

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

  viewAppended:->

    vmName = @getData()

    @addSubView @icon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon"

    @addSubView @vmInfo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-info'
      partial  : "#{vmName}"

    @addSubView @vmDesc = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-desc'
      partial  : if (vmName.indexOf KD.nick()) < 0 then 'Shared VM' \
                                                   else 'Personal VM'

    @addSubView @chevron = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "chevron"

    @vm.info @getData(), @bound 'checkVMState'

  click:->
    KD.singletons.windowController.addLayer @delegate
    @delegate.once 'ReceivedClickElsewhere', =>
      @delegate.emit "DeselectAllItems"

  checkVMState:(err, vm, info)->
    return unless vm is @getData()

    if err or not info
      @unsetClass 'online'
      return warn err

    switch info.state
      when "RUNNING"
        @setClass 'online'

      when "STOPPED"
        @unsetClass 'online'

  partial:-> ''