class NominateModal extends KDModalView

  constructor: (options = {}, data) ->
    options.cssClass       = "nominate-modal"
    options.width          = 400
    options.overlay       ?= yes

    super options, data

  viewAppended:->
    @unsetClass 'kdmodal'

    @addSubView new KDCustomHTMLView
      partial : """
        <div class="logo"></div>
        <div class="header"></div>

        <h2>
          Nominate Koding for
        </h2>
        <h1>
          Best New Startup 2013
        </h1>

        <p>
          The
          <a href="http://techcrunch.com/events/7th-annual-crunchies-awards/" target="_blank">7th Annual Crunchies Awards</a> are here and we at Koding
          would like to humbly ask for your nomination for
          Best Startup 2013.
        </p>

        <p>
          We are eternally grateful for your support.
        </p>

        <a href="http://crunchies2013.techcrunch.com/nominated/?MTk6S29kaW5n" target="_blank">
          <div class="button">
            Nominate Koding!
          </div>
        </a>
      """
