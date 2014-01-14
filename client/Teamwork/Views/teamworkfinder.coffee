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
    else if fileType is "file" and FSHelper.isPublicPath nodeData.path
      @addPreviewIcon node

  addExporterIcon: (node) ->
    node.exporter = new KDCustomHTMLView
      cssClass    : "tw-export"
      click       : => @emit "ExportRequested", node

    node.addSubView node.exporter

  addPreviewIcon: (node) ->
    node.previewer = new KDCustomHTMLView
      cssClass    : "tw-preview"
      click       : => @emit "PreviewRequested", node

    node.addSubView node.previewer
