class TBCampaignHomePageView extends JView

  constructor: (options= {}, data) ->

    options.cssClass = KD.utils.curry "campaign-container", options.cssClass

    super options, data

  createDigitsMarkup: ->
    leftInByte = @getData().content.diskSpaceLeftMB * 1024 * 1024
    leftInTB   = KD.utils.formatBytesToHumanReadable leftInByte, 3
    [left]     = leftInTB.split " "
    left       = "99.99"  if left is "100.00"
    [tb, gb]   = left.split "."
    tb         = ["0", tb.first]  if tb.length is 1

    return """
        <div class="digit">#{tb[0] or 0}</div>
        <div class="digit">#{tb[1] or 0}</div>
        <div class="separator">,</div>
        <div class="digit">#{gb[0] or 0}</div>
        <div class="digit">#{gb[1] or 0}</div>
        <div class="digit">#{gb[2] or 0}</div>
    """

  getDaysLeft: ->
    oneDayInMs = 86400000 # 24 * 60 * 60 * 1000
    endDate    = @getData().content.endDate # smt like 2014-01-30T00:00:00.000Z
    diffInMs   = new Date(endDate).getTime() - Date.now()
    daysLeft   = (diffInMs / oneDayInMs).toFixed 2

    if daysLeft > 2
      return "#{parseInt daysLeft, 10} days"
    else if 2 > daysLeft > 1
      return "1 day"
    else
      hoursLeft = parseInt 24 * daysLeft, 10
      return if hoursLeft is 1 then "1 hour" else "#{hoursLeft} hours"

  pistachio: ->
    digits   = @createDigitsMarkup()
    daysLeft = @getDaysLeft()

    return """
      <section id="campaign">
        <div id="banner">
          <div class="container">
            <div class="campaign-logo"></div>
            <div class="divider first">
              <div class="icon"></div>
            </div>
            <div class="text">
              <span>Giving away <span>100 TB</span></span>
              <p class="rounded">4GB for every sign up</p>
            </div>
            <div class="divider last">
              <div class="icon"></div>
            </div>
            <div class="counter">
              <div class="digits">
                #{digits}
              </div>
              <p class="rounded digits">GB left, get yours now!</p>
            </div>
          </div>
        </div>
        <div id="signup">
          <div class="container">
            <span class="label">Sign up now and get your VM with <span>4GB storage</span></span>
            <p>
              <span class="icon timer"></span>
              <span class="remaining">#{daysLeft} left, hurry up!</span>
              <span class="icon arrow"></span>
            </p>
          </div>
        </div>
      </section>
    """