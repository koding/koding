BONGO_MQ = switch KD.env
  when 'beta'
    new Pusher 'a19c8bf6d2cad6c7a006', encrypted: yes
  else
    new Pusher 'a6f121a130a44c7f5325', encrypted: yes