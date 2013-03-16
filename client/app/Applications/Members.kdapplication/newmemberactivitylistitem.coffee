class NewMemberActivityListItem extends MembersListItemView
  constructor: (options = {}, data) ->
    options.avatarSizes = [30, 30]

    super options,data

  pistachio:->
    """
      <span>{{> @avatar}}</span>
      <div class='member-details'>
        <header class='personal'>
          <h3>{{> @profileLink}}</h3>
        </header>
        <p>{{ @utils.applyTextExpansions #(profile.about), yes}}</p>
        <footer>
          <span class='button-container'>{{> @followButton}}</span>
        </footer>
      </div>
    """

class NewMemberListItem extends KDListItemView
  constructor: (options = {}, data) ->
    options.tagName   = "li"

    super options, data

  fetchUserDetails: ->
    KD.remote.cacheable "JAccount", @getData().id, (err, res) =>
      @addSubView new NewMemberActivityListItem {}, res

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()
    @fetchUserDetails()

  pistachio: -> ""
