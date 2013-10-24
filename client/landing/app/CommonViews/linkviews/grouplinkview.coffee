class GroupLinkView extends LinkView

	constructor: (options = {}, data) ->
		super options, data
		@setClass "profile"

	render:->
		slug = @getData().slug
		@setAttribute "href", "/#{slug}"
		super

	pistachio:->
		super "{{#(title)}}"
