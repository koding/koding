class Flag extends Base
  #
  #FlagOption = new Schema
  #  option      : String
  #  signatures  : [ObjectId]
  #
  FlagSchema = new Schema
    type              : String
    label             : String
    results           : Mixed
    options           : [TextSchema]
    isMultiple        : 
      type            : Boolean
      default         : no
    customOptionLabel : String
  
  @__defineGetter__ 'schema', -> FlagSchema
  
  constructor:(options)->
    {
      @label
      @options
      @isMultiple
      @customOptionLabel
    } = options
  
  fetchIsEligibile:(options, callback)->
    
    callback yes
      
  populate:(metadata, flagData)->
    
    {id, option, flagType, metadataType} = flagData
    
    for flag, spliceIndex in metadata.flags 
      if flag.type is flagType
        oldFlag = flag
        break
    
    spliceIndex = -1 if spliceIndex is metadata.flags.length
    
    newFlagData = {
      @label
      @options
      @isMultiple
      @customOptionLabel
      results:  {}
      type:     flagType or metadataType
    }
    
    thisOption  = 
      (if oldFlag
        _(newFlagData.results).extend oldFlag.results
        metadata.flags[spliceIndex]?.results?[option]) or []
    
    register = new Register
    
    newFlagData.results[option] = _(thisOption).chain()
      .push(id)
      .select((id)-> register.sign id)
    .value()
    
    if ~spliceIndex
      metadata.set "flags.#{spliceIndex}", newFlagData
    else
      metadata.flags.push newFlagData
    
    return metadata.flags
    
  #
  #results: 
  #  upvote  :  ['myAccountId','somebodysAccountId']
  #  downvote:  ['yourAccountId','ids','id','id']
  #
  #results: 
  #  upvote  :  ['myAccountId']
  #  downvote:  ['yourAccountId']
  #  custom  :  [{id:'myAccountId', text:'lorum ipsum sit'}]
  #
  #options   :  ['upvote','downvote']
  #isMultiple: no
  #
  #metadata.flag('upvote', account)
  #
  #
   