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

    { name, monthPrice, yearPrice } = @getOptions()

    modal = new PaymentModal
      state          :
        subscription : name
        monthPrice   : monthPrice
        yearPrice    : yearPrice


