class IDE.MachineItemView extends NFileItemView

  constructor: (options = {}, data) ->

    options.cssClass or= "vm"

    super options, data

    {@machine}      = @getData()

    @machineInfo    = new KDCustomHTMLView
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
      callback      : @bound 'updateRoot'

    KD.singletons.computeController.on "revive-#{@machine._id}", =>
      @machineInfo.updatePartial @machine.getName()

  updateRoot: (path) ->
    finder = @getData().treeController.getDelegate()
    finder?.updateMachineRoot @machine.uid, path


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

  pistachio:->
    return """
      <div class="vm-header">
        {{> @machineInfo}}
        <div class="buttons">
          {{> @terminalButton}}
          <span class='chevron'></span>
        </div>
      </div>
      {{> @folderSelector}}
    """
