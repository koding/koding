class BadgeListItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    @removeButton = new KDButtonView
      title       : "Delete"
      #cssClass    : "delete-badge clean-red"
      callback    : =>
        modal = new BadgeRemoveForm {}, badge:@getData()

    @editButton = new KDButtonView
      title       : "Edit"
      cssClass    : "edit-badge"
      callback    : =>
        modal = new BadgeUpdateForm {}, badge : @getData()

    @assignButton = new KDButtonView
      title       : "Assign"
      cssClass    : "assign-badge"
      callback    : =>
        modal = new BadgeUpdateForm {}, badge : @getData()

  viewAppended: JView::viewAppended

  pistachio:->
    {iconURL} = @getData()
    """
      <div class="icon">
        <img src="#{iconURL}"/>
      </div>
      <p class="name">
        {{#(title)}}
      </p>
      <div class="buttons">
        {{> @editButton}}
        {{> @assignButton}}
      </div>

    """
