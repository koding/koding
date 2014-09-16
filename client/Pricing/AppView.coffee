class PricingAppView extends KDView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    options.cssClass = KD.utils.curry "content-page pricing", options.cssClass

    super options, data

    @initViews()
    @initEvents()


  initViews: ->

    @header = new KDCustomHTMLView
      partial   : "Our pricing, your terms"
      tagName   : "h4"
      cssClass  : "pricing-heading"

    @headerDescription = new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'pricing-description'
      partial   : "
        Get started for free or go right into high gear with one of our aid plans.
        Our simple pricing is designed to help you get the most out of your Koding experience.
        Trusted by your peers worldwide.
      "

    @plans = new PricingPlansView

    @info = new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'pricing-footer'
      partial   : "
        All packs contain <span>SSL, Sudo Access, IDE, Terminal, SSH Access and Custom Domains</span>
      "

    @learnMoreLink = new CustomLinkView
      title    : "Learn more"
      cssClass : "learn-more"
      href     : "/"


  initEvents: ->
    @plans.on 'PlanSelected', @bound 'planSelected'


  planSelected: (name, monthPrice, yearPrice) ->
    workflowController = new PaymentWorkflow {name, monthPrice, yearPrice, view: this}


  pistachio: ->
    """
      {{> @header}}
      {{> @headerDescription}}
      {{> @plans}}
      {{> @info}}
      {{> @learnMoreLink}}
    """


