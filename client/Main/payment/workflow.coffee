class PaymentWorkflow extends KDController

  @interval:
    MONTH  : 'month'
    YEAR   : 'year'

  @subscription  :
    FREE         : 'free'
    HOBBYIST     : 'hobbyist'
    DEVELOPER    : 'developer'
    PROFESSIONAL : 'professional'

  constructor: (options = {}, data) ->

    KodingAppsController.appendHeadElements
      identifier : "stripe"
      items      : [
        {
          type   : 'script'
          url    : "https://js.stripe.com/v2/"
        }
      ]

    super options, data

    @start()


  start: ->

    { name, price } = @getOptions()

    modal = new PaymentModal
      state          :
        subscription : name
        interval     : PaymentWorkflow.MONTH_INTERVAL
        price        : price


