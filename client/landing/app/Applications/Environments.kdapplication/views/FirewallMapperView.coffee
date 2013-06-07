class FirewallMapperView extends KDView

  constructor:(options={}, data) ->
    super options, data

    domain = @getData()?.domain

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

    @addSubView new FirewallRuleFormView


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
      callback: ->
        console.log 'block listing'

    @whiteListButton = new KDButtonView
      title    : "+ White List"
      callback : ->
        console.log 'white listing' 

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