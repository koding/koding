
{projectRoot} = KONFIG
console.log projectRoot

fs = require 'fs'
defaultIndex = "#{projectRoot}/website/default.html"

loadingAnimation = """
  <div id="main-koding-loader" class="kdview main-loading">
    <figure>
      <ul>
        <li></li>
        <li></li>
        <li></li>
        <li></li>
        <li></li>
        <li></li>
      </ul>
    </figure>
  </div>
"""

loggedOutPage = fs.readFileSync defaultIndex, 'utf-8'
loggedInPage  = loggedOutPage.replace '<!--LOADER-->', loadingAnimation

module.exports = {loggedInPage, loggedOutPage}
