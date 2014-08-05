class IDE.MachineItemView extends NFileItemView

  constructor: (options = {}, data) ->

    options.cssClass or= "vm"

    super options, data

    {@machine}      = @getData()

    @vmInfo         = new KDCustomHTMLView
      tagName       : 'span'
      cssClass      : 'vm-info'
      partial       : @machine.getName()

    @terminalButton = new KDButtonView
      cssClass      : 'terminal'
      callback      : =>
        data.treeController.emit 'TerminalRequested', @machine
        KD.getSingleton('windowController').setKeyView null

    @folderSelector = new KDSelectBox
      selectOptions : @createSelectOptions()
      callback      : @bound 'updateVMRoot'

    @vm = KD.getSingleton 'vmController'
    @vm.on 'StateChanged', @bound 'checkVMState'

    @vm.fetchVMDomains data.vmName, (err, domains) =>
      if not err and domains.length > 0
        @vmInfo.updatePartial domains.first

  updateVMRoot: (path) ->
    data    = @getData()
    vm      = data.vmName
    finder  = data.treeController.getDelegate()

    finder?.updateMachineRoot vm, path

  createSelectOptions: ->
    currentPath = @getData().path
    nickname    = KD.nick()
    parents     = []
    nodes       = currentPath.split '/'

    for x in [ 0...nodes.length ]
      nodes = currentPath.split '/'
      path  = nodes.splice(1,x).join '/'
      parents.push "/#{path}"

    parents = _.unique parents.reverse()
    items   = []
    root    = "/home/#{KD.nick()}/"

    for path in parents when path
      items.push title: path.replace(root, '~/'), value: path

    return items

  checkVMState:(err, vm, info)->
    return unless vm is @getData().vmName

    if err or not info
      @unsetClass 'online'
      return warn err

    if info.state is "RUNNING"
    then @setClass 'online'
    else @unsetClass 'online'

  pistachio:->
    return """
      <div class="vm-header">
        {{> @vmInfo}}
        <div class="buttons">
          {{> @terminalButton}}
          <span class='chevron'></span>
        </div>
      </div>
      {{> @folderSelector}}
    """
