class SkillTagAutoCompletedItem extends KDAutoCompletedItem
  constructor: (options = {}, data) ->
    options.cssClass = "clearfix"
    super options, data
    @tag = new TagLinkView {}, @getData()

  viewAppended: JView::viewAppended

  pistachio: -> "{{> @tag}}"

  click: (event) ->
    delegate = @getDelegate()
    delegate.removeFromSubmitQueue this if $(event.target).is 'span.close-icon'
    delegate.getView().$input().trigger event
