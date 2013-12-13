class FormWorkflow.Visualization extends JView
  viewAppended: ->
    @setClass 'formworkflow-visualization-container'


    { workflow } = @getOptions()

    @graph = jsnx.DiGraph()

    @graphViewport = new KDView
      cssClass: 'formworkflow-visualization'

    @controls = new KDButtonBar
      cssClass      : 'controls'
      buttons       :
        Next        :
          callback  : =>
            # r = workflow.nextRequirement()
            # foo = {}
            # foo[r] = 1
            # workflow.collectData foo

    super()

    {gate: entry} = workflow.collector

    @walk entry

    jsnx.draw @graph,
      element: @graphViewport.getElement()
      with_labels: true
      node_style:
        stroke: (d) ->
          d.data.color

      label_style:
        fill: "black"

  getStroke: (node) ->
    switch node?.constructor?.name
      when 'Junction' then 'green'
      when 'Any'      then 'blue'
      when 'All'      then 'red'
      else                 'gray'

  walk: (node, parent) ->
    for field, value of node.fields

      @graph.add_node field, color: @getStroke node.children[field]
      
      @graph.add_edge parent, field  if parent
      
      @walk node.children[field], field  if field of node.children

  pistachio: ->
    """
    {{> @graphViewport}}
    {{> @controls}}
    """