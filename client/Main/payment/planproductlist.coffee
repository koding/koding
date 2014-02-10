class PlanProductListView extends KDView
  viewAppended: ->
    {planOptions: {resourceQuantity, userQuantity}} = @getOptions()

    if userQuantity
      @addSubView new KDCustomHTMLView partial: "#{userQuantity}x User"
      @addSubView new KDCustomHTMLView partial: "#{resourceQuantity}x Resource Packs"
