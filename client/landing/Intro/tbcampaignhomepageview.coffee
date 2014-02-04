class TBCampaignHomePageView extends JView

  constructor: (options= {}, data) ->

    options.cssClass = KD.utils.curry "campaign-container", options.cssClass

    super options, data

  createDigitsMarkup: ->
    left       = "00.000"
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
    # endDate    = Date().now() # 2014-01-30T00:00:00.000Z
    diffInMs   = 0 # new Date(endDate).getTime() - Date.now()
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
              <p class="rounded digits">No space left</p>
            </div>
          </div>
        </div>
        <div id="signup">
          <div class="container" style="text-align:center">

            <span class="label">
              <a href="http://blog.koding.com/2014/01/100tb-is-gone-in-1-day-crazy100tbweek-is-over/" style="text-decoration:none; color:#1AAF5D;">
                100TB is gone <span>#Crazy100TBWeek</span> is Over :(
              </a>
            </span>

          </div>
        </div>
      </section>
    """