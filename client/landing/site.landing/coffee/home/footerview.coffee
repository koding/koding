module.exports = class FooterView extends KDView

  constructor: (options = {}, data) ->

    options.tagName   = 'footer'
    options.cssClass  = 'main-footer'

    super options, data

    @setPartial @partial()


  partial: ->
    """
    <div class="inner-container clearfix">
      <nav class="footer-block">
        <a href="/">Copyright © #{(new Date).getFullYear()} Koding, Inc</a>
        <a href="/Teams/Showcase">Showcase</a>
        <a href="/Teams/">Pricing</a>
        <a href="/Teams/Help">Help</a>
        <a href="/Teams/Privacy-Terms">Privacy Terms</a>
      </nav>
    </div>
    """
