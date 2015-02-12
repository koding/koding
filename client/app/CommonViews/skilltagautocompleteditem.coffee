class SkillTagAutoCompletedItem extends KDAutoCompletedItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->
    options.cssClass = "clearfix"
    super options, data
    @tag = new TagLinkView {}, @getData()

  pistachio: -> "{{> @tag}}"

  click: (event) ->
    delegate = @getDelegate()
    delegate.removeFromSubmitQueue this if $(event.target).is 'span.close-icon'
    delegate.getView().$input().trigger event
