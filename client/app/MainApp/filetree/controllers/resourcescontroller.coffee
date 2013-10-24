class ResourcesController extends KDListViewController

  constructor:(options = {}, data)->
    options       = $.extend
      view        : new ResourcesView
      wrapper     : no
      scrollView  : no
    , options

    super options, data

    @getView().on 'DeselectAllItems', @bound 'deselectAllItems'
    KD.getSingleton("vmController").on 'VMListChanged', @bound 'reset'
    KD.getSingleton('notificationController').on 'VMMaintenance', @bound 'reset'

  reset:->
    # FIXME ~ BK
    # cmp = (a, b)->
    #   [groupA, vmA] = a.split('~')
    #   [groupB, vmB] = b.split('~')
    #   if groupA is groupB
    #   then vmA    > vmB
    #   else groupA > groupB

    finder = KD.getSingleton('finderController')
    finder.emit 'EnvironmentsTabHide'

    @removeAllItems()

    vmController = KD.getSingleton("vmController")
    vmController.resetVMData()
    vmController.fetchVMs yes, (err, vms)=>
      return  unless vms
      # vms.sort cmp
      stack   = []
      vms.forEach (hostname)=>
        group = hostname.replace('.kd.io','').split('.').last or KD.defaultSlug
        stack.push (cb)->
          KD.remote.cacheable group, (err, res)->
            if err or not res
              warn "Fetching group info failed for '#{group}' Group."
              cb null
            else
              group = res?.first or 'koding' # KD.defaultSlug
              vmController.info hostname, (err, vm, info)->
                cb null,
                  vmName     : hostname
                  groupSlug  : group?.slug  or 'koding' # KD.defaultSlug
                  groupTitle : group?.title or 'Koding'
                  info       : info

      async.parallel stack, (err, result)=>
        warn err  if err
        @instantiateListItems result
        @deselectAllItems()
        finder.emit 'EnvironmentsTabShow'

  instantiateListItems:(items)->
    super items.filter Boolean

class ResourcesView extends KDListView

  constructor:(options = {}, data)->
    options = $.extend
      cssClass  : 'resources-list'
      itemClass : ResourcesListItem
    , options

    super options, data

class ResourcesListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass or= 'vm'
    super options, data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

  viewAppended:->

    {vmName} = @getData()

    @addSubView @icon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "icon"

    @addSubView @vmInfo = new KDCustomHTMLView
      tagName    : 'span'
      partial    : "#{vmName}"
      cssClass   : 'vm-info'
      attributes :
        title    : "#{vmName}"

    @vm.fetchVMDomains vmName, (err, domains)=>
      unless err and domains.length > 0
        @vmInfo.updatePartial domains.first
        @vmInfo.setAttribute "title", domains.first
        # @setTooltip
        #   title : "Also reachable from: <br/><li>" + domains.join '<li>'

    @vmTypeText = if (vmName.indexOf KD.nick()) < 0 then 'Shared VM' \
                                                    else 'Personal VM'

    @addSubView @vmDesc = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-desc'
      partial  : @vmTypeText

    @addSubView @buttonTerm = new KDButtonView
      icon     : yes
      iconOnly : yes
      cssClass : 'vm-terminal'
      callback :->
        KD.getSingleton("appManager").open "WebTerm", params: {vmName}, forceNew: yes

    @addSubView @chevron = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "chevron"

    {vmName, info} = @getData()
    @checkVMState null, vmName, info

  click:->
    KD.getSingleton("windowController").addLayer @delegate
    @delegate.once 'ReceivedClickElsewhere', =>
      @delegate.emit "DeselectAllItems"

    {vmName} = @getData()

    if @state is "MAINTENANCE"
      items =
        customView1 : new KDView
          cssClass  : "vm-maintenance"
          partial   : "This VM is under maintenance, please try again later."
    else
      items =
        customView1        : new NVMToggleButtonView {}, {vmName}
        customView2        : new NMountToggleButtonView {}, {vmName}
        'Re-initialize VM' :
          disabled         : KD.isGuest()
          callback         : ->
            KD.getSingleton("vmController").reinitialize vmName
            @destroy()
        'Delete VM'        :
          disabled         : KD.isGuest()
          callback         : ->
            KD.getSingleton("vmController").remove vmName
            @destroy()
          separator        : yes
        'Open VM Terminal' :
          callback         : ->
            KD.getSingleton("appManager").open "WebTerm", params: {vmName}, forceNew: yes
            @destroy()
          separator        : yes
        customView3        : new NVMDetailsView {}, {vmName}

    offset = @chevron.$().offset()
    contextMenu = new JContextMenu
      menuWidth   : 200
      delegate    : @chevron
      x           : offset.left + 26
      y           : offset.top  - 19
      arrow       :
        placement : "left"
        margin    : 19
      lazyLoad    : yes
    , items

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName
    return warn err if err or not info

    # Reset the state
    @unsetClass 'online maintenance'
    @buttonTerm.hide()
    @vmDesc.updatePartial @vmTypeText

    @state = info.state

    # Rebuild the state
    switch info.state
      when "RUNNING"
        @setClass   'online'
        @buttonTerm.show()
      when "MAINTENANCE"
        @setClass   'maintenance'
        @vmDesc.updatePartial "UNDER MAINTENANCE"
      else
        @buttonTerm.hide()

  partial:-> ''
