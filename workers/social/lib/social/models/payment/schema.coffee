module.exports =

  feeUnit   :
    type    : String
    default : 'months'
    enum    : ['fee unit should be "months" or "days"',[
      'months'
      'days'
    ]]

  tags    :
    type  :[String]
    set   : (value) -> (value.map (tag)-> tag.trim()).filter(Boolean)