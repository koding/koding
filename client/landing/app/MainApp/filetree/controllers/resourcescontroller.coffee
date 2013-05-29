class ResourcesController extends KDListViewController

  constructor:(options = {}, data)->
    options       = $.extend
      view        : new ResourcesView
      wrapper     : no
      scrollView  : no
    , options

    super options, data

    @getView().on 'DeselectAllItems', @bound 'deselectAllItems'
    KD.singletons.vmController.on 'VMListChanged', @bound 'reset'
    @reset()

  reset:->
    cmp = (a, b)->
      [groupA, vmA] = a.split('~')
      [groupB, vmB] = b.split('~')
      if groupA == groupB
        vmA > vmB
      else
        groupA > groupB

    KD.singletons.vmController.resetVMData()
    KD.singletons.vmController.fetchVMs (err, vms)=>
      @removeAllItems()
      vms.sort cmp
      @instantiateListItems vms  unless err
      @deselectAllItems()

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

    offset = @chevron.$().offset()
    vmName = @getData()
    contextMenu = new JContextMenu
      menuWidth   : 200
      delegate    : @chevron
      x           : offset.left + 26
      y           : offset.top  - 19
      arrow       :
        placement : "left"
        margin    : 19
      lazyLoad    : yes
    ,
      customView1        : new NVMToggleButtonView {}, {vmName}
      customView2        : new NMountToggleButtonView {}, {vmName}
      'Re-initialize VM' :
        callback         : ->
          KD.singletons.vmController.reinitialize vmName
          @destroy()
        separator        : yes
      'Open VM Terminal' :
        callback         : ->
          appManager.open "WebTerm", params: {vmName}, forceNew: yes
          @destroy()

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