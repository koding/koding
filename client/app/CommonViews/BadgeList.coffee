class BadgeList extends JView
  constructor: (options = {}, data) ->
    super options, data

    @listController       = new KDListViewController
      startWithLazyLoader : no
      view                : new KDListView
        type              : "badges"
        cssClass          : "badge-profile-list"
        itemClass         : BadgeItem
    @list = @listController.getView()
    KD.remote.api.JBadge.getUserBadges @getOptions().memberData, (err, badges)=>
      @listController.instantiateListItems badges

  pistachio:->
    """
    <p>User Badges</p>
    {{> @list}}
    """


class BadgeItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

  pistachio:->
    """
      <div class="badge"><img src="{{#(iconURL)}}"/>{{#(title)}}</div>
    """

  viewAppended: JView::viewAppended
