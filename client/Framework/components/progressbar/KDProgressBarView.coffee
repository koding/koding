class KDProgressBarView extends KDCustomHTMLView
	constructor:(options = {})->
		options.tagName	  = "div"
		options.cssClass += " progressBarContainer"
		
		super options

	viewAppended:->
		@createBar()

	createBar:(value, label)->
		@addSubView @bar = new KDCustomHTMLView
			tagName		: "div"
			cssClass	: "bar"
		@addSubView @darkLabel = new KDCustomHTMLView
			tagName		: "span"
			cssClass 	: "darkLabel"
		@bar.addSubView @lightLabel = new KDCustomHTMLView
			tagName		: "span"
			cssClass 	: "lightLabel"

	updateBar:(value, label)->
		@bar.$().css 'width', value
		@darkLabel.updatePartial "#{label}&nbsp;"
		@lightLabel.updatePartial "#{label}&nbsp;"