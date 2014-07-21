class IDE.FinderItem extends NFinderItem

  getChildConstructor: (type) ->
    switch type
      when "vm"         then IDE.VMItemView
      when "folder"     then NFolderItemView
      when "section"    then NSectionItemView
      when "mount"      then NMountItemView
      when "brokenLink" then NBrokenLinkItemView
      else NFileItemView

class IDE.FinderPane extends IDE.Pane

  constructor: (options = {}, data) ->

    super options, data

    appManager = KD.getSingleton 'appManager'

    appManager.open 'Finder', (finderApp) =>
      fc = @finderController = finderApp.create
        addAppTitle   : no
        treeItemClass : IDE.FinderItem

      @addSubView fc.getView()
      @bindListeners()
      fc.reset()

  bindListeners: ->
    mgr = KD.getSingleton 'appManager'
    fc  = @finderController

    fc.on 'FileNeedsToBeOpened', (file) ->
      file.fetchContents (err, contents) ->
        mgr.tell 'IDE', 'openFile', file, contents
        KD.getSingleton('windowController').setKeyView null

    fc.treeController.on 'TerminalRequested', (vm) ->
      mgr.tell 'IDE', 'openVMTerminal', vm

    @on 'VMMountRequested',   (vm) -> fc.mountVm vm

    @on 'VMUnmountRequested', (vm) -> fc.unmountVm vm.hostnameAlias
