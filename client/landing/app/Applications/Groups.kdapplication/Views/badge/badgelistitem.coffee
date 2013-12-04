class BadgeListItem extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data

    @editButton = new KDButtonView
      title       : "Edit"
      cssClass    : "edit-badge"
      callback    : =>
        modal     = new BadgeUpdateForm {itemList: this}, badge : @getData()

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
      </div>

    """