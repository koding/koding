class TeamworkEnvironmentsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title       = "Teamwork Environments"
    options.cssClass    = "tw-environments-modal clean-gray"
    options.overlay     = yes
    options.width       = 800

    super options, data

    environments        = [ "Python", "Ruby", "MongoDB", "HTML5", "Facebook", "NodeJS" ]
    @addSubView wrapper = new KDCustomHTMLView cssClass: "tw-environments-wrapper"

    environments.forEach (environment) =>
      wrapper.addSubView new TeamworkEnvironmentFlipWidget
        cssClass        : "tw-#{environment.toLowerCase()}"
        content         : """
          <p>Facebook</p>
          <span>
            Start discovering all about the Facebook App Development.
            This environment is designed to solve app login and permission problems.
            Also we will show you how you can easily implement FB Like, Share and Comment widgets for your site.
          </span>
        """
        callback        : =>
          @handleEnvironmentSelection environment
          @destroy()

  handleEnvironmentSelection: (environment) ->
    @getDelegate().handleEnvironmentSelection environment



class TeamworkEnvironmentFlipWidget extends JView

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


