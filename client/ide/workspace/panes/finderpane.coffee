class FinderPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    vmController = KD.getSingleton "vmController"
    vmController.fetchDefaultVmName (vmName) =>
      @finder = new NFinderController
        nodeIdPath       : "path"
        nodeParentIdPath : "parentPath"
        contextMenu      : yes
        useStorage       : no

      @addSubView @finder.getView()
      @finder.updateVMRoot vmName, "/home/#{KD.nick()}"
