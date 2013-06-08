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

    @blockListItemClass = new KDListItemView
    @blockListItemClass.on "click", (event)->
      console.log "block list item clicked."

    @blockListController = new KDListViewController
      itemClass   : @blockListItemClass
      viewOptions :
        cssClass  : 'block-list'

    if domain and domain.blockList
      @blockListController.instantiateListItems []

    @whiteListItemClass = new KDListItemView
    @whiteListItemClass.on "click", (event)->
      console.lig "white list item clicked"

    @whiteListController = new KDListViewController
      itemClass   : @whiteListItemClass
      viewOptions :
        cssClass  : 'white-list'

    if domain and domain.whiteList
      @whiteListController.instantiateListItems []

    @addSubView (new FirewallRuleFormView {}, {domain:domain})


class FirewallRuleFormView extends KDView

  constructor:(options={}, data)->
    super options, data

    @ruleInput = new KDInputView
      tooltip : 
        title     : "You can enter IP, IP Range or a Country name."
        placement : "bottom"

    @ruleInput.unsetClass 'kdinput'

    @blockListButton = new KDButtonView
      title   : "+ Block List"
      callback: =>
        console.log 'block listing'
        @updateDomainRules "blockList", "addToSet", @ruleInput.getValue()

    @whiteListButton = new KDButtonView
      title    : "+ White List"
      callback : =>
        console.log 'white listing' 
        @updateDomainRules "whiteList", "addToSet", @ruleInput.getValue()


  updateDomainRules:(field, op, value)->
    fieldMethod = switch field
      when "whiteList" then "updateWhiteList"
      when "blockList" then "updateBlockList"
    KD.remote.api.JDomain[fieldMethod] {domainName:@getData().domain.domain, op, value}, (err)->
      if err
        new KDNotificationView
          type  : "top"
          title : "An error occured while updating the #{field}. Please try again."
      else
        @ruleInput.setValue ""
        new KDNotificationView
          type  : "top"
          title : "The #{field} is updated."

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()


  pistachio:->
    """
    <div class="rule-form">
      <div style="float: left;">
        <label for="rule-input">Add a rule:</label>
        {{> @ruleInput }}
      </div>
      <div style="float: left'">
        {{> @blockListButton }}
        {{> @whiteListButton }}
      </div>
    </div>
    """