class FooterView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = 'footer'
    options.cssClass = 'main-footer'

    super options, data

    @setPartial @partial()


  partial: ->
    """
    <div class="inner-container clearfix">

      <nav class="footer-block">
        <a href="/Pricing">Pricing</a>
        <a href="/Activity">Community</a>
        <a href="/About">About</a>
        <a href="/Legal">Legal</a>
      </nav>

      <nav class="footer-block">
        <a class='social tw' href="http://twitter.com/koding"></a><a class='social fb' href="http://facebook.com/koding"></a>
        <a href="/">Copyright © #{(new Date).getFullYear()} Koding, Inc</a>
      </nav>
    </div>
    """
