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

    @addSubView (new FirewallRuleFormView {}, {domain:domain})

    @addSubView @blockListView = new KDCustomHTMLView
      partial: "<h3>Block List for #{domain.domain}</h3>"
      cssClass: 'block-list-view'

    @blockListView.addSubView @blockListController.getView()
    
    @addSubView @whiteListView = new KDCustomHTMLView
      partial: "<h3>White List for #{domain.domain}</h3>"
      cssClass: 'white-list-view'

    @whiteListView.addSubView @whiteListController.getView()


class FirewallListItemView extends KDListItemView

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <table>
        <tr>
          <td>{{ #(rule) }}</td>
          <td>Edit</td>
        </tr>
      </table>
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

    @blockListButton = new KDButtonView
      title   : "+ Block List"
      callback: =>
        @updateDomainRules "blockList", "addToSet", @ruleInput.getValue()

    @whiteListButton = new KDButtonView
      title    : "+ White List"
      callback : =>
        @updateDomainRules "whiteList", "addToSet", @ruleInput.getValue()


  updateDomainRules:(field, op, value)->
    fieldMethod = switch field
      when "whiteList" then "updateWhiteList"
      when "blockList" then "updateBlockList"
    KD.remote.api.JDomain[fieldMethod] {domainName:@getData().domain.domain, op, value}, (err)=>
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