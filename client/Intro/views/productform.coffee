class IntroPricingProductForm extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "product-form", options.cssClass
    super options, data

    @developerPlan = new IntroDeveloperPlan
    @developerPlan.on "PlanSelected", @bound "selectPlan"

    @teamPlan = new IntroTeamPlan cssClass: "hidden"
    @teamPlan.on "PlanSelected", @bound "selectPlan"

    @toggle        = new KDMultipleChoice
      cssClass     : "pricing-toggle"
      labels       : ["DEVELOPER", "TEAM"]
      defaultValue : ["DEVELOPER"]
      multiple     : no
      callback     : =>
        switch @toggle.getValue()
          when "DEVELOPER"
            @developerPlan.show()
            @teamPlan.hide()
          when "TEAM"
            @developerPlan.hide()
            @teamPlan.show()

  showDeveloperPlan: ->
    @developerPlan.show()
    @teamPlan.hide()

  showTeamPlan: ->
    @developerPlan.hide()
    @teamPlan.show()

  selectPlan: (tag, options) ->
    appManager = KD.singleton "appManager"
    appManager.require "Pricing", (app) ->
      app.selectPlan tag, options
      appManager.open "Pricing"

  pistachio: ->
    """
    <div class="inner-container">
      <header class="clearfix">
        <h2>Flexible Pricing for Developers and Teams</h2>
        <p>Either you are coding by yourself or coding with<br>your team, we got plans for you.</p>
        {{> @toggle}}
      </header>
      <div class="plan-selection">
        {{> @developerPlan}}
        {{> @teamPlan}}
      </div>
    </div>
    """
