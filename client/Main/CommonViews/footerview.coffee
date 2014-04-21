class FooterView extends JView

  constructor: ->

    super

    # $.ajax
    #   url     : 'http://blog.koding.com/?json=get_recent_posts'
    #   success : (result)->
    #     log result
    #   failure : ->
    #     log 'failed'


  pistachio: ->
    """
    <footer>
      <div class="inner-container clearfix">
        <article class="footer-block about-koding">
          <h5>ABOUT KODING</h5>
          <p>Koding is a developer community and cloud development environment where developers come together and code in the browser – with a real development server to run their code. Developers can work, collaborate, write and run apps without jumping</p>
          <a href="/About">More about Koding</a>
        </article>

        <nav class="footer-block">
          <h5>COMPANY</h5>
          <a href="/About">ABOUT KODING</a>
          <a href="http://learn.koding.com" target="_blank">KODING UNIVERSITY</a>
          <a href="mailto:hello@koding.com">CONTACT US</a>
          <a href="/toc.html" target="_blank">TERMS AND CONDITIONS</a>
          <a href="/privacy.html" target="_blank">PRIVACY POLICY</a>
          <a href="http://status.koding.com" target="_blank">STATUS</a>
        </nav>

        <nav class="footer-block">
          <h5>COMMUNITY</h5>
          <a href='http://blog.koding.com'>KODING BLOG</a>
          <a href='https://www.facebook.com/kodingcom/events'>MEETUPS</a>
          <a href='#'>NEWSLETTER</a>
          <a href='http://stories.koding.com'>TESTIMONALS</a>
          <a href='https://koding-cdn.s3.amazonaws.com/brand/koding-logo.pdf'>BRAND GUIDELINES</a>
        </nav>

        <nav class="footer-block blog">
          <h5>KODING BLOG</h5>
          <a href="#">Koding introduces 250TB week</a>
          <a href="#">Just opensourced KDFramework</a>
          <a href="#">Hired Jony Ive for office management</a>
          <a href="#">Cried all day, funny stuff</a>
          <a href="#">Last of us</a>
        </nav>

        <cite></cite>

        <address>2014 © Koding, Inc. 358 Brannan Street, San Francisco, CA, 94107</address>
        <span class="we-love-you">Lovingly made in Istanbul & San Francisco <3</span>

        <div class="social-links">
          <a href="http://twitter.com/koding">TWITTER</a> · <a href="http://facebook.com/kodingcom">FACEBOOK</a>
        </div>
      </div>
    </footer>
    """