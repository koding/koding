class DemosMainView extends KDScrollView
  
  viewAppended:()-> 
    
    @addSubView form = new KDFormView
      callback : -> 
        log arguments, "form submitted"

    form.addSubView input = new KDInputView
      name              : "kk"
      validate          :
        rules           :
          required      : yes
          # maxLength     : 20
          # minLength     : 10
          rangeLength   : [8,25]
          # email         : yes
          # creditCard    : yes

    form.addSubView new KDButtonView
      title: "disable range validation"
      callback : ->
        delete input.getOptions().validate.rules.rangeLength

    form.addSubView new KDButtonView
      title: "enable range validation"
      callback : ->
        input.getOptions().validate.rules.rangeLength = [8,25]



