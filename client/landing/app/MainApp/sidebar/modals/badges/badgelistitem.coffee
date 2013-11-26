class BadgeListItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    @removeButton = new KDButtonView
      title       : "Delete"
      cssClass    : "delete-badge clean-red"
      callback    : =>
        modal = new BadgeRemoveForm {}, badge:@getData()


    @editButton = new KDButtonView
      title       : "Edit"
      cssClass    : "edit-badge clean-yellow"
      callback    : =>
        modal = new BadgeUpdateForm {}, badge : @getData()

  viewAppended: JView::viewAppended

  pistachio:->
      """
        <div class="icon"><img src="{{#(iconURL)}}"/></div>
        <div class="name">{{#(title)}}</div>
          {{> @removeButton}}
          {{> @editButton}}
      """


class BadgeAssignmentListItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    {@badge,userHas} = @getData()
    @badgeChangeButton = new KDMultipleChoice
      cssClass         : "dark"
      defaultValue     : if userHas then "ON" else "OFF"
      callback         : (state)=>
        state = if state is "ON" then on else off
        @getDelegate().emit "BadgeStateChanged", state, @badge

  viewAppended: JView::viewAppended

  pistachio:->
    {title,iconURL} = @badge
    """
      <div class="badge">
        <img src="#{iconURL}"/>
        <span>#{title}</span>
      </div>
      <div>{{>@badgeChangeButton}}</div>
    """
