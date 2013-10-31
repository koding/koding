class GroupPlanProduct extends JView
  pistachio: ->
    """
    <div class="clearfix">
      {{ #(planCode) }} {{ #(qty) }}
    </div>
    """