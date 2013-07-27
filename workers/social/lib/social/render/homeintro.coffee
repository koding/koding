module.exports = (loggedIn = no)->

  """
  <div id="home-intro" class="kdview#{if loggedIn then ' out' else ''}">
    <div>
      <h2 class="slogan">A new way for<br>developers to work.</h2>
      <h3 class="slogan-continues">Koding is your new development computer, sign up to get a free VM and use it in your browser.</h3>
      <ul>
        <li><a class="" href="#"><i></i><img src="/images/timedude.jpg"></a></li>
      </ul>
    </div>
    <aside>
      <form class="kdformview with-fields">
        <div class="kdview formline gh register gh-gray">
          <div class="input-wrapper">
            <button type="button" class="kdbutton register gh-gray with-icon" id="kd-134"><span class="icon octocat"></span><span class="button-title">Sign up with GitHub</span></button>
          </div>
        </div>
        <div class="kdview formline or">
          <div class="input-wrapper">
            <span class="">or</span>
          </div>
        </div>
        <div class="kdview formline username">
          <div class="input-wrapper">
            <input name="username" type="text" class="kdinput text " placeholder="Desired username">
          </div>
        </div>
        <div class="kdview formline email">
          <div class="input-wrapper">
            <input name="email" type="email" class="kdinput email " placeholder="Your email address">
          </div>
        </div>
        <div class="kdview formline password">
          <div class="input-wrapper">
            <input name="password" type="password" class="kdinput text " placeholder="Type a password">
          </div>
        </div>
        <div class="kdview formline button-field clearfix">
          <button type="submit" class="kdbutton register orange" id="kd-148"><span class="icon hidden"></span><span class="button-title">REGISTER</span></button>
        </div>
      </form>
      <div class="toc">By signing up, you agree to our <a href="#">terms of service</a> and <a href="#">privacy policy</a>.</div>
    </aside>
  </div>
  """
