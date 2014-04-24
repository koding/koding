class PricingTeamSlidersView extends TeamPlan

  constructor: (options = {},  data) ->
    options.tagName  = 'section'
    options.cssClass = 'team-plan'

    super options, data

    @sectionTitle    = new KDHeaderView
      type      : 'medium'
      cssClass  : 'general-title'
      title     : 'For large teams, here you can scale your resource pack
      alongside your team size'

  pistachio: ->
    """
    {{> @sectionTitle}}
    <div class='custom-plan-container'>
      <div class="sliders-container">
        {{> @resourcePackSlider}}
        {{> @userSlider}}
      </div>
      <div class="summary-container">
        {{> @summary}}
      </div>
    </div>
    """


