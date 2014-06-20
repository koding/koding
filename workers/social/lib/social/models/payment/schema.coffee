module.exports =

  feeUnit   :
    type    : String
    default : 'month'
    enum    : ['fee unit should be "month" or "days"',[
      'month'
      'days'
    ]]

  tags    :
    type  :[String]
    set   : (value) -> (value.map (tag)-> tag.trim()).filter(Boolean)
