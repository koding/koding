kd                  = require 'kd'
JView               = require 'app/jview'
KDView              = kd.View
KDTabView           = kd.TabView
KDTabPaneView       = kd.TabPaneView
KDCustomHTMLView    = kd.CustomHTMLView
FooterView          = require 'app/commonviews/footerview'
CustomLinkView      = require 'app/customlinkview'
BranchTabHandleView = require './views/branchtabhandleview'

IndividualsView     = require './views/individualsview'
TeamsView           = require './views/teamsview'


module.exports = class PricingAppView extends KDView


  JView.mixin @prototype


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "content-page pricing", options.cssClass

    super options, data

    @initViews()

    @on 'LoadPlan', @bound 'handleLoadPlan'


  handleLoadPlan: ->

    @individualsView?.loadPlan()


  initViews: ->

    @featureBranchTabView = new KDCustomHTMLView
      tagName               : 'section'
      cssClass              : 'feature-branch'

    @featureTabView = new KDTabView
      hideHandleCloseIcons  : yes
      tabHandleClass        : BranchTabHandleView

    @featureTabView.addPane teams = new KDTabPaneView
      name                  : 'For Teams'
      subPath               : 'Teams'

    teams.addSubView @teamsView = new TeamsView

    @featureTabView.addPane individuals = new KDTabPaneView
      name                  : 'For Individuals'
      subPath               : 'Individuals'

    @individualsView  = new IndividualsView
      delegate              : this

    individuals.addSubView @individualsView

    @featureBranchTabView.addSubView @featureTabView

    @footer       = @initFooter()
    @kodingFooter = new FooterView

    { router } = kd.singletons

    [firstPath, ..., lastPath] = router.getCurrentPath().split '/'
    @featureTabView.showPaneByIndex 0  if lastPath is 'Teams'


  switchBranch: (type) ->

    index = if type is 'teams' then 0 else 1
    @featureTabView.showPaneByIndex index


  initFooter: ->

    features = [
      'Full sudo access'
      'Custom sub-domains'
      'Realtime collaboration'

      'VMs hosted on Amazon EC2'
      'Publicly accessible IP'
      'Audio/Video in collaboration'

      'SSH Access'
      'Ubuntu 14.04'
      'Custom IDE shortcuts'

      'Unlimited workspaces'
      'Built-in IDE and Terminal'
      'Connect your own VM'
    ]

    footer = new KDCustomHTMLView
      cssClass : 'pricing-footer'

    footer.addSubView new KDCustomHTMLView
      tagName : 'h4'
      partial : 'All plans include:'

    footer.addSubView featuresWrapper = new KDCustomHTMLView
      tagName  : 'ul'
      cssClass : 'features clearfix'

    features.forEach (feature) ->
      featuresWrapper.addSubView new KDCustomHTMLView
        tagName  : 'li'
        cssClass : 'single-feature'
        partial  : feature

    footer.addSubView new CustomLinkView
      title    : "Learn more about all of Koding's great features"
      cssClass : "learn-more"
      href     : "/Features"

    return footer


  pistachio: ->
    """
      {{> @featureBranchTabView}}
      {{> @footer}}
      {{> @kodingFooter}}
    """
