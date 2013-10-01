module.exports = (loggedIn = no)->
  getCounters  = require './counters'

  """
  <div id="home-intro" class="kdview#{if loggedIn then ' out' else ''}">
    <section>
      <div>
        <h2 class="slogan">A new way for<br>developers to work.</h2>
        <h3 class="slogan-continues">
          <span>Software development has finally evolved.</span>
          <br>
          <span>It's now social, in the browser and free.</span>
        </h3>
      </div>
      <aside>
        <form>
          <div class="formline gh"><button type="button" class="kdbutton register gh-gray with-icon" id="kd-134"><span class="icon octocat"></span><span class="button-title">Sign up with GitHub</span></button></div>
          <div class="formline or">or</div>
          <div class="formline signup">
            <button onclick="location.href='#!/Register'" type="button" class="kdbutton register orange" id="kd-135">
              <span class="icon hidden"></span>
              <span class="button-title">Sign up with email</span>
            </button>
          </div>
          <div class="formline or">or check what Koding is:</div>
          <ul class="large">
            <li><a class="" href="#"><i></i><img src="/images/video/twomins.jpg"></a></li>
            <li><a class="" href="#"><i></i><img src="/images/video/timedude.jpg"></a></li>
          </ul>
          <div class="formline"><div class="tos">By signing up, you agree to our <a href="/tos.html" target="_blank">terms of service</a> and <a href="/privacy.html" target="_blank">privacy policy</a>.</div></div>
        </form>
      </aside>
    </section>
    <a class='try' href="/Develop">Go ahead &amp; try!</a>
    #{getCounters()}
  </div>
  """

