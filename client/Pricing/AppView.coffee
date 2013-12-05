class PricingAppView extends KDView

  viewAppended: ->
    @addSubView @getOptions().workflow

    @thankYou = new KDView
      partial: "Thanks a lot, buddy!  Check your email!"
    @thankYou.hide()

    @addSubView @thankYou

  showThankYou: ->
    @getOptions().workflow.hide()

    @thankYou.show()