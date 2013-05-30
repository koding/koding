class VMMainView extends JView

  constructor:(options={}, data)->

    options.cssClass or= "vms"
    data or= {}
    super options, data

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
      kc = KD.singletons.kiteController
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

  getVMInfo: (vmName, callback)->
    kc = KD.singletons.kiteController
    kc.run
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
                status = 'off'
              else
                status = 'on'

              cb null, {
                name   : name
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

    @switch = new KDOnOffSwitch
      size         : 'tiny'
      labels       : ['I', 'O']
      defaultValue : data.status == 'on'
      cssClass     : 'fr'
      callback     : (state)=>
        @getData().controller.emit "State", @, state

  clicked: (event)->
    @getData().controller.emit "Clicked", @

  viewAppended:()->
    super()

    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    data = @getData()
    """
    <div>
      <span class="vm-icon #{data.type}"></span>
      <span class="vm-status #{data.status}"></span>
      <span class="vm-title">
        #{data.name} - #{data.group}
      </span>
      <span class="vm-domain">http://#{data.domain}</span>
      {{> @switch }}
    </div>
    """