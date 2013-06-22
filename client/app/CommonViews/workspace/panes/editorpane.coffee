class EditorPane extends Pane

  constructor: (options = {}, data) ->

    options.cssClass = "editor-pane"

    super options, data

    @container = new KDView

    require ["ace/ace"], (ace) =>
      @editor = ace.edit @container.getDomElement()[0]

  pistachio: ->
    """
      {{> @container}}
    """