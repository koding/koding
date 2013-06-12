class FirewallMapperView extends KDView

  constructor:(options={}, data) ->
    data or= {}
    super options, data

    domain = data?.domain

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

    @addSubView new KDCustomHTMLView
      partial: 'Select a domain to continue.'

  updateViewContent:->
    domain = @getData().domain

    @destroySubViews()

    @blockListController = new KDListViewController
      itemClass   : FirewallListItemView
      viewOptions :
        cssClass  : 'block-list'

    blockListItems = []
    [1..10].forEach (i) ->
      generatedIp = Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1);
      blockListItems.push {rule:generatedIp, mode:'deny'}

    @blockListController.instantiateListItems blockListItems

    if domain.blockList
      blockList = ({rule:item} for item in domain.blockList)
      @blockListController.instantiateListItems blockList

    @whiteListController = new KDListViewController
      itemClass   : FirewallListItemView
      viewOptions :
        cssClass  : 'white-list'

    if domain.whiteList
      whiteList = ({rule:item} for item in domain.whiteList)
      @whiteListController.instantiateListItems whiteList

    whiteListItems = []
    [1..10].forEach (i) ->
      generatedIp = Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1) + "." + Math.floor((Math.random()*254)+1);
      whiteListItems.push {rule:generatedIp, mode:'allow'}
    @whiteListController.instantiateListItems whiteListItems

    @addSubView (new FirewallRuleFormView {}, {domain:domain})

    @addSubView @blockListView = new KDCustomHTMLView
      partial: "<h3>Deny List for #{domain.domain}</h3>"
      cssClass: 'block-list-view'

    @blockListView.addSubView @blockListController.getView()
    
    @addSubView @whiteListView = new KDCustomHTMLView
      partial: "<h3>Allow List for #{domain.domain}</h3>"
      cssClass: 'white-list-view'

    @whiteListView.addSubView @whiteListController.getView()


class FirewallListItemView extends KDListItemView

  viewAppended:->
    @unsetClass 'kdview'
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="fw-li-view">
      <div class="fw-li-rule">{{ #(rule) }}</div>
      <div class="fw-li-actions">
        <span class="icon edit">Edit</span> |
        <span class="icon delete">Delete</span>
      </div>
    </div>
    """


class FirewallRuleFormView extends KDCustomHTMLView

  constructor:(options={}, data)->
    options.cssClass = "rule-form-view"
    super options, data

    @ruleInput = new KDInputView
      tooltip : 
        title     : "You can enter IP, IP Range or a Country name."
        placement : "bottom"

    @ruleInput.unsetClass 'kdinput'

    @denyButton = new KDButtonView
      title   : "Deny"
      callback: =>
        @updateDomainRules "deny", @ruleInput.getValue()

    @allowButton = new KDButtonView
      title    : "Allow"
      callback : =>
        @updateDomainRules "allow", @ruleInput.getValue() 


  updateDomainRules:(mode, value)->
    ruleName   = if value.match /[0-9+]/ then "ip" else "country"
    domainName = @getData().domain.domain
    
    ruleInfo =
      rule    : value
      mode    : mode
      enabled : "yes"
      name    : ruleName

    KD.remote.api.JDomain.createProxyRule
      domainName : domainName
      ruleInfo   : ruleInfo
    , (response) ->
      alert response


  viewAppended:->
    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    """
    <div class="rule-form">
      <div style="float: left; margin-right: 5px;">
        <label for="rule-input">Add a rule:</label>
        {{> @ruleInput }}
      </div>
      <div style="float: left'">
        {{> @denyButton }}
        {{> @allowButton }}
      </div>
    </div>
    """