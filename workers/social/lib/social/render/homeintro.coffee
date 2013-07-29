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
          <span>It is now social, in the browser,</span>
          <br>
          <span>and free.</span>
        </h3>
      </div>
      <aside>
        <form class="kdformview with-fields">
         <div class="formline gh"><button type="button" class="kdbutton register gh-gray with-icon" id="kd-134"><span class="icon octocat"></span><span class="button-title">Sign up with GitHub</span></button></div>
         <div class="formline or">or</div>
         <div class="formline signup"><button type="button" class="kdbutton register orange" id="kd-135"><span class="icon hidden"></span><span class="button-title">Sign up with email</span></button></div>
         <div class="formline"><div class="toc">By signing up, you agree to our <a href="#">terms of service</a> and <a href="#">privacy policy</a>.</div></div>
        </form>
      </aside>
    </section>
    #{getCounters()}
  </div>
  """

