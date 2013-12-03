class TeamworkPlaygroundsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title       = "Teamwork Playgrounds"
    options.cssClass    = "tw-playgrounds-modal clean-gray"
    options.overlay     = yes
    options.width       = 800

    super options, data

    playgrounds         = [ "Python", "Ruby", "MongoDB", "HTML5", "Facebook", "NodeJS" ]
    @addSubView wrapper = new KDCustomHTMLView cssClass: "tw-playgrounds-wrapper"

    playgrounds.forEach (playground) =>
      wrapper.addSubView new TeamworkPlaygroundFlipWidget
        cssClass        : "tw-#{playground.toLowerCase()}"
        content         : """
          <p>Facebook</p>
          <span>
            Start discovering all about the Facebook App Development.
            This playground is designed to solve app login and permission problems.
            Also we will show you how you can easily implement FB Like, Share and Comment widgets for your site.
          </span>
        """
        callback        : =>
          @handlePlaygroundSelection playground
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
        <div class="front"></div>
        <div class="back">
          {{> @backSide}}
        </div>
      </div>
    """


