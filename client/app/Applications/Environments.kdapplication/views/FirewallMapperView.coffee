class FirewallMapperView extends KDView

  constructor:(options={}, data) ->
    data or= {}
    super options, data

    domain = data?.domain

    @on "domainChanged", (item)->
      @getData().domain = item.data
      @updateViewContent()

  updateViewContent:->
    domain = @getData().domain

    @blockListItemClass = new KDListItemView
    @blockListItemClass.on "click", (event)->
      console.log "block list item clicked."

    @blockListController = new KDListViewController
      itemClass   : @blockListItemClass
      viewOptions :
        cssClass  : 'block-list'

    @blockListController.instantiateListItems @domain.blockList if domain?.blockList

    @whiteListItemClass = new KDListItemView
    @whiteListItemClass.on "click", (event)->
      console.lig "white list item clicked"

    @whiteListController = new KDListViewController
      itemClass   : @whiteListItemClass
      viewOptions :
        cssClass  : 'white-list'

    @whiteListController.instantiateListItems @domain.whiteList if domain?.whiteList

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
        @updateRules "blocklist", "addToSet", @ruleInput.getValue()

    @whiteListButton = new KDButtonView
      title    : "+ White List"
      callback : =>
        console.log 'white listing' 
        @updateRules "whitelist", "addToSet", @ruleInput.getValue()


  updateRules:(field, op, value)->
    KD.remote.api.JDomain.updateRules {field, op, value}, (err)->
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