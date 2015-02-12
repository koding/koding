class PlanProductListView extends KDView
  viewAppended: ->
    {planOptions} = @getOptions()
    return  unless planOptions
    {resourceQuantity, userQuantity} = planOptions
    if userQuantity
      @addSubView new KDCustomHTMLView partial: "#{userQuantity}x User"
      @addSubView new KDCustomHTMLView partial: "#{resourceQuantity}x Resource Packs"
