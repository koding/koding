class FooterView extends JView

  constructor: (options = {}, data) ->

    options.tagName  = 'footer'
    options.cssClass = 'main-footer'

    super options, data

    # $.ajax
    #   url     : 'http://blog.koding.com/?json=get_recent_posts'
    #   success : (result)->
    #     log result
    #   failure : ->
    #     log 'failed'


  pistachio: ->
    """
    <div class="inner-container clearfix">
      <article class="footer-block about-koding">
        <h5>ABOUT KODING</h5>
        <p>Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping</p>
        <a href="/About">More about Koding</a>
      </article>

      <nav class="footer-block">
        <h5>COMPANY</h5>
        <a href="http://learn.koding.com" target="_blank">KODING UNIVERSITY</a>
        <a href="/About">JOBS</a>
        <a href="/tos.html" target="_blank">TERMS AND CONDITIONS</a>
        <a href="/privacy.html" target="_blank">PRIVACY POLICY</a>
        <a href="mailto:hello@koding.com" target='_self'>CONTACT US</a>
        <a href="http://status.koding.com" target="_blank">STATUS</a>
      </nav>

      <nav class="footer-block">
        <h5>COMMUNITY</h5>
        <a href='/Activity/Public' target='_self'>ACTIVITY</a>
        <a href='http://blog.koding.com'>KODING BLOG</a>
        <a href='https://www.facebook.com/kodingcom/events'>MEETUPS</a>
        <a href='http://stories.koding.com'>TESTIMONIALS</a>
        <a href='https://koding-cdn.s3.amazonaws.com/brand/koding-logo.pdf'>BRAND GUIDELINES</a>
        <a href='/copyright.html' target='_blank'>COPYRIGHT/DMCA GUIDELINES</a>
        <a href='/acceptable.html' target='_blank'>ACCEPTABLE USER POLICY</a>
      </nav>

      <nav class="footer-block blog">
        <h5>KODING BLOG</h5>
        <a href="http://blog.koding.com/2014/03/announcing-devtools-now-everyone-can-make-koding-apps/">Now Everyone Can Make Koding Apps!</a>
        <a href="http://blog.koding.com/2014/03/you-ask-we-do-were-extending-crazy250tbweek-with-another-week-and-250tb-enjoy/">You ask, we do! We’re extending #Crazy250TBWeek with another week and +250TB – Enjoy :)</a>
        <a href="http://blog.koding.com/2014/02/use-your-own-domain-with-koding-for-free/">Use your own domain with Koding! For free!</a>
        <a href="http://blog.koding.com/2014/02/groups-and-pricing-deployed/">Groups and Pricing – deployed!</a>
        <a href="http://blog.koding.com">Other posts...</a>
      </nav>

      <cite></cite>

      <address>#{(new Date).getFullYear()} © Koding, Inc. 358 Brannan Street, San Francisco, CA, 94107</address>

      <div class="social-links">
        <a href="http://twitter.com/koding">TWITTER</a> · <a href="http://facebook.com/kodingcom">FACEBOOK</a>
      </div>
    </div>
    """
