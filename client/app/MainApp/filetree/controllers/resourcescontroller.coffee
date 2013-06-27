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

    vmController.fetchVMs (err, vms)=>
      return  unless vms
      # vms.sort cmp
      stack   = []
      vms.forEach (hostname)=>
        group = hostname.replace('.kd.io','').split('.').last or 'koding'
        stack.push (cb)->
          KD.remote.cacheable group, (err, res)->
            return cb err  if err
            group = res?.first or 'koding'
            data  =
              vmName     : hostname
              groupSlug  : group?.slug  or 'koding'
              groupTitle : group?.title or 'Koding'
            cb null, data

      async.parallel stack, (err, result)=>
        @instantiateListItems result  unless err
        @deselectAllItems()
        finder.emit 'EnvironmentsTabShow'

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

  viewAppended:->

    {vmName} = @getData()

    @addSubView @icon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon"

    @addSubView @vmInfo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-info'
      partial  : "#{vmName}"
      attributes:
        title  : "#{vmName}"

    @vm.fetchVMDomains vmName, (err, domains)=>
      unless err and domains.length > 0
        @vmInfo.updatePartial "#{domains.first}"
        @vmInfo.setDomAttributes title : "#{domains.first}"
        # @setTooltip
        #   title : "Also reachable from: <br/><li>" + domains.join '<li>'

    @addSubView @vmDesc = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'vm-desc'
      partial  : if (vmName.indexOf KD.nick()) < 0 then 'Shared VM' \
                                                   else 'Personal VM'

    @addSubView @buttonTerm = new KDButtonView
      icon     : yes
      iconOnly : yes
      cssClass : 'vm-terminal'
      callback :->
        KD.getSingleton("appManager").open "WebTerm", params: {vmName}, forceNew: yes

    @addSubView @chevron = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "chevron"

  click:->
    KD.getSingleton("windowController").addLayer @delegate
    @delegate.once 'ReceivedClickElsewhere', =>
      @delegate.emit "DeselectAllItems"

    offset = @chevron.$().offset()
    {vmName} = @getData()
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
          KD.getSingleton("vmController").reinitialize vmName
          @destroy()
      'Delete VM'        :
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
