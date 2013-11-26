class TeamworkPlaygroundsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title       = "Teamwork Playgrounds"
    options.cssClass    = "tw-playgrounds-modal clean-gray"
    options.overlay     = yes
    options.width       = 800

    super options, data

    @addSubView wrapper = new KDCustomHTMLView cssClass: "tw-playgrounds-wrapper"

    @getOptions().playgrounds.forEach (playground) =>
      {name, description} = playground
      wrapper.addSubView new TeamworkPlaygroundFlipWidget
        cssClass        : "tw-#{name.toLowerCase()}"
        coverPath       : playground.icon
        content         : """<p>#{name}</p><span>#{description}</span>"""
        callback        : =>
          @getDelegate().handlePlaygroundSelection name
          @destroy()

  handlePlaygroundSelection: (playground) ->
    @getDelegate().handlePlaygroundSelection playground


class TeamworkPlaygroundFlipWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "flip-container", options.cssClass

    super options, data

    @backSide  = new KDView
      partial  : @getOptions().content

  click: ->
    @getOptions().callback()

  pistachio: ->
    """
      <div class="flipper">
        <div class="front">
          <img src="#{@getOptions().coverPath}" />
        </div>
        <div class="back">
          {{> @backSide}}
        </div>
      </div>
    """
