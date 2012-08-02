class Metadata.Harmful
  
  Metadata.defineFlags @, 
    new Flag
      label   : t 'Why do you consider this script to be harmful?'
      options : [
        t 'This script failed to do what it purported.'
        t 'It caused damage to my enviornment.'
        t 'It corrupted or destroyed my data.'
      ]
      customOptionLabel : t 'Other'
      isMultiple        : yes