class DemosMainView extends KDScrollView

  viewAppended:()->



    # @addSubView form = new KDFormView
    #   callback : ->
    #     log arguments, "form submitted"

    # form.addSubView input = new KDInputView
    #   name              : "kk"
    #   validate          :
    #     rules           :
    #       required      : yes
    #       # maxLength     : 20
    #       # minLength     : 10
    #       rangeLength   : [8,25]
    #       # email         : yes
    #       # creditCard    : yes

    # form.addSubView new KDButtonView
    #   title: "disable range validation"
    #   callback : ->
    #     validation = input.getOptions().validate
    #     delete validation.rules.rangeLength
    #     input.setValidation validation

    # form.addSubView new KDButtonView
    #   title: "enable range validation"
    #   callback : ->
    #     validation = input.getOptions().validate
    #     validation.rules.rangeLength = [8,25]
    #     input.setValidation validation



