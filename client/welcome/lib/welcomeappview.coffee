JView = require 'app/jview'
FooterView = require 'app/commonviews/footerview'


module.exports = class AboutAppView extends JView

  constructor:->

    super

    @once 'viewAppended', -> global.scrollTo 0, 0

    @footer = new FooterView

  pistachio : ->
    """
    <section class='introduction'>
      <h2>About Koding</h2>
      <p class='main-description'>
        Koding is a developer community and cloud development environment where
        developers come together and code in the browser – with a real development
        server to run their code. Developers can work, collaborate, write and
        run apps without jumping through hoops and spending unnecessary money.
      </p>
      <p class='bottom-note'>
        Koding gives developers three essentials that they need as they begin their
        cloud based development projects:
      </p>
      <ul class='bottom-note'>
        <li>A robust development environment in the form of virtual machines(VMs)</li>
        <li>Amazing development tools in the form of an online IDE and browser based Terminal to operate on this VM</li>
        <li>A vibrant community where developers can exchange ideas and learn</li>
      </ul>
      <p class='bottom-note'>
        So if you have a project that you are thinking of starting or if you want to learn
        a new technology or if you just want to tinker, Koding is right place to do it.
        Say goodbye to your localhost and develop in the cloud.
      </p>
    </section>
    <section class='stats'>
      <div class='inner-container clearfix'>
        <div class='stat-item vms'><span>18 Million+</span> VMs spun up</div>
        <div class='stat-item code'><span>1 Billion+</span>lines of code</div>
        <div class='stat-item developers'><span>500,000+</span>developers</div>
      </div>
    </section>
    <section class='contact'>
      <div class='inner-container clearfix'>
        <h3>Get in touch with us</h3>
        <a href="mailto:business@koding.com" class='contact-item sales'>business@koding.com</a>
        <a href="mailto:support@koding.com" class='contact-item support'>support@koding.com</a>
        <a href="mailto:apply@koding.com" class='contact-item careers'>apply@koding.com</a>
      </div>
    </section>
    <section class='where'>
      <h3>Where we are?</h3>
      <address>358 Brannan Street, San Francisco, CA, 94107</address>
      <div class='map-container'>
        <iframe width="100%" height="100%" frameborder="0" style="border:0" src="https://www.google.com/maps/embed/v1/place?q=Koding%2C%20Brannan%20Street%2C%20San%20Francisco%2C%20CA%2C%20United%20States&key=AIzaSyAr4ZF8XJqh1ru1Fvw8f5e27KleSYDcRGs"></iframe>
      </div>
    </section>
    <section class='assets'>
      <div class='inner-container clearfix'>
        <h3>Brand Assets</h3>
        <div class='brand-box logo'>
          <div class='info'>
            Koding Logo <br>
            <a href='https://brandfolder.com/koding' target='_blank'>.pdf</a> <a href='https://brandfolder.com/koding' target='_blank'>.ai</a>
          </div>
          <div class='examples'>
            <figure></figure>
          </div>
        </div>
        <div class='brand-box font'>
          <div class='info'>
            Koding Font <br>
            <a href='#'>Google webfonts</a>
          </div>
          <div class='examples'>
            <figure></figure>
            <a href='http://google.com/fonts/specimen/Asap' target='_blank'>google.com/fonts/specimen/Asap</a>
          </div>
        </div>
      </div>
    </section>
    {{> @footer}}
    """


