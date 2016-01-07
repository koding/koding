kd      = require 'kd'
KDView  = kd.View


module.exports = class FooterView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = 'footer'
    options.cssClass = 'main-footer'

    super options, data

    @setPartial @partial()


  partial: ->
    """
    <div class="inner-container clearfix">
      <nav class="footer-block">
        <a href="/">Koding.com</a>
      </nav>

      <nav class="footer-block">
        <a href="#">Blog</a>
        <a href="/Activity">Community</a>
        <a href="/About">About</a>
        <a href="/Legal">Legal</a>
      </nav>
    </div>
    """
