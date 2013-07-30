class VMsMainView extends JView

  constructor:(options={}, data)->

    options.cssClass or= "vms"
    data or= {}
    super options, data

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'
    @vmList = []

    @vmListController = new KDListViewController
      startWithLazyLoader : no
      viewOptions         :
        type              : "vm-list"
        cssClass          : "vm-list"
        itemClass         : VMListItemView

    @vmListView = @vmListController.getView()

    @on "Clicked", (item)=>
      @graphView.update? item
      @vmListController.deselectAllItems()
      @vmListController.selectSingleItem item

    @on "State", (item, state)=>
      cmd = if state then 'vm.start' else 'vm.stop'
      kc = KD.getSingleton("kiteController")
      kc.run
        kiteName  : 'os',
        vmName    : item.data.name,
        method    : cmd

    @graphView = new VMDetailView
    @splitView = new KDSplitView
      type      : 'vertical'
      resizable : no
      sizes     : ['30%', '70%']
      views     : [@vmListView, @graphView]

    @loadItems()

  checkVMState:(err, vm, info)->
    return  if not @vmList[vm]
    if err or not info or not info.state is "RUNNING"
    then @vmList[vm].updateStatus no
    else @vmList[vm].updateStatus yes

  getVMInfo: (vmName, callback)->
    KD.getSingleton("kiteController").run
      kiteName  : 'os',
      vmName    : vmName,
      method    : 'vm.info'
    , callback

  loadItems:->
    @vmListController.removeAllItems()
    @vmListController.showLazyLoader no

    KD.remote.api.JVM.fetchVms (err, vms)=>
      if err
        @vmListController.hideLazyLoader()
      else
        stack = []
        vms.forEach (name)=>
          stack.push (cb)=>

            @getVMInfo name, (err, info)=>
              if err or info.state != 'RUNNING'
                status = no
              else
                status = yes

              cb null, {
                vmName : name
                group  : 'Koding'
                domain : 'bahadir.kd.io'
                type   : 'personal'
                status : status
                controller : @
              }

        async.parallel stack, (err, results)=>
          @vmListController.hideLazyLoader()
          unless err
            @vmListController.instantiateListItems results

  pistachio:->
    """
      {{> @splitView}}
    """


class VMDetailView extends KDView
  constructor: (options, data) ->
    super options, data

class VMListItemView extends KDListItemView
  constructor: (options, data) ->
    options.cssClass or= "vm-item"
    options.click = @bound "clicked"

    super options, data

    {controller,vmName} = @getData()
    controller.vmList[vmName] = @

    @statusIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "vm-status"

    @switch = new KDOnOffSwitch
      size         : 'tiny'
      labels       : ['I', 'O']
      defaultValue : data.status
      cssClass     : 'fr'
      callback : (state)=>
        if state
        then controller.vm.start vmName
        else controller.vm.stop  vmName

    @updateStatus @getData().status

  clicked: (event)->
    @getData().controller.emit "Clicked", @

  updateStatus:(state)->
    unless state
      @statusIcon.unsetClass "vm-status-on"
      @switch.setOff no
    else
      @statusIcon.setClass "vm-status-on"
      @switch.setOn no

  viewAppended:->
    super()

    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    data = @getData()
    """
    <div>
      <span class="vm-icon #{data.type}"></span>
      {{> @statusIcon }}
      <span class="vm-title">
        #{data.vmName} - #{data.group}
      </span>
      <span class="vm-domain">http://#{data.domain}</span>
      {{> @switch }}
    </div>
    """