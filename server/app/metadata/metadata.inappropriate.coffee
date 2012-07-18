class Metadata.Inappropriate
  # TODO:  I just filled this in with e.g. sort of text - hc
  aboutMe = new Flag
    label   : t 'This post is about me, or someone I know.'
    options : [
      t 'It harrasses me.'
      t 'It harrasses someone I know.'
      t 'It infringes on my copyright.'
    ]
  
  otherReason = new Flag 
    label   : t 'This post is inappropriate for another reason.'
    options : [
      t "It's graphic or obscene in nature."
      t "It contains nudity."
    ]
    customOptionLabel : t 'Other'
    isMultiple        : yes
  
  Metadata.defineFlags @, {aboutMe, otherReason}