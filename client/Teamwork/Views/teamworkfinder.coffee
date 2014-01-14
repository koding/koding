class TeamworkFinderItem extends NFinderItem

  removeHighlight: ->
    super
    @exporter?.destroy()
    @previewer?.destroy()


class TeamworkFinderTreeController extends CollaborativeFinderTreeController

  selectNode: (node) ->
    super

    nodeData = node.getData()
    fileType = nodeData.type

    if fileType is "folder"
      @addExporterIcon node

  addExporterIcon: (node) ->
    node.exporter = new KDCustomHTMLView
      cssClass    : "tw-export"
      click       : => @emit "ExportRequested", node

    node.addSubView node.exporter
