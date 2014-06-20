FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

ENV HOME /root

RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN mkdir -p /root/.ssh
RUN apt-get install -y golang nodejs git graphicsmagick openssh-client python

RUN echo "-----BEGIN RSA PRIVATE KEY-----"                                  >/root/.ssh/id_rsa
RUN echo "MIIEpAIBAAKCAQEAxJUfKx05K3kymTkgISnFOoh1PY/jJ3dlUnAUE8WqCXlDQi+C" >>/root/.ssh/id_rsa
RUN echo "FIJO+pKGNNyo8z2fF43iCGfc9h3a0qvhvyWY4f6tkllSBdWLWwV2O8edRJXIwMyu" >>/root/.ssh/id_rsa
RUN echo "ku8SIXeNg0Qg0+iqZKUZJEnv6MSUcDNejFS0AVz4Dw3pSfLT+xTEWD4j9hM6I8BQ" >>/root/.ssh/id_rsa
RUN echo "qEYM2wqkyqjjIVS0bGQE0buohLiWymI4J95B5MbKuofo5eAUxkFOA+vTt66RSbWB" >>/root/.ssh/id_rsa
RUN echo "BAFVg0jIDMJ4bXU28JBO8GXt0N7GkpLRPd1IEjoJ8d0iKghT6KMtwzEWyr2k6Qta" >>/root/.ssh/id_rsa
RUN echo "3FybcFbjhKJneitK+ln5BXiU917p3cYAG3xRDwIDAQABAoIBACyBKiZDnm7GKHth" >>/root/.ssh/id_rsa
RUN echo "4HFBmKIwxIIkciO8Nxcbwp/bTyyH5H82bDeibKjzxShwkFtJJxxZBcQrZ23cwm6R" >>/root/.ssh/id_rsa
RUN echo "dTEmHN+FHdyVFim196+qo+LSxTsCwglMDXW8ZBlpjIMcSGZRNUpFylRZ3NOQtZ5V" >>/root/.ssh/id_rsa
RUN echo "MuGIR5xLZOlbl+Yi8HTWdcEYiGGsAPemKTaalSAK91ak1kkb0wDpUJU/NK01glSk" >>/root/.ssh/id_rsa
RUN echo "HqqsUAzmGmd19VLJhRRKNVpGbI+zhJbgl7rn0CynTdJDDtuwYwQZYjxtHDp3/UiW" >>/root/.ssh/id_rsa
RUN echo "lLkBToe74L7WrNH6ZZgCCFDFx9nUAnbHPEvh6vnN5s+Ce46F69pKWihvBEyH23UT" >>/root/.ssh/id_rsa
RUN echo "8wzl3IECgYEA7AnHjlK0buZLJr1IQ5YD8vd7LIK7wwHeaPOh+dhZrvn3twfibSRu" >>/root/.ssh/id_rsa
RUN echo "55ew/2wmd/E5yyzgdDBGQCjPKwfs/2FnPg01KlMObAkGn0KG8j0/NecQdlv9PJgv" >>/root/.ssh/id_rsa
RUN echo "lriLY7rm5O40aKMevdQ3PinvkS+KTUdbd6GfVyC77zh9HnIhW2xllc8CgYEA1TUg" >>/root/.ssh/id_rsa
RUN echo "pzKQSwn8fxyKctKFf+4QEogdUPIWLgJCF8kgJGaSAl1r/wwEbQIhF8SeTEL199Cm" >>/root/.ssh/id_rsa
RUN echo "5uk8w6oGlsNbPgZkF8PBuwFS3x2cbIbC+/HdWZmiPmx96o/pEZ9sWKQyX46nN9es" >>/root/.ssh/id_rsa
RUN echo "5HqxULgB0m/9AxzAtFZTwV5pBWkXdIwBQuyroMECgYEAwB7JpeddY7Lg0nxYeGJ/" >>/root/.ssh/id_rsa
RUN echo "fmC/iiAy8evwet5rJbBadxiQ7xJk009HUgvfDleaDCB1WRGC9C9iztAop67A0bEX" >>/root/.ssh/id_rsa
RUN echo "VqNrdbK612aVVEXTDxKZA6e6d4wyWALLIVO+aQN08juMvuqemAZGnLuHelYGrRX6" >>/root/.ssh/id_rsa
RUN echo "tioARuum7HS/KmvdCMv293MCgYEAhS8x3aAFaQqs8w52IfIGOPsSiTED9yuy1TzN" >>/root/.ssh/id_rsa
RUN echo "4qPd8z8rmFSZgPIV1a6N05YcOJFfq1Vo3Tf3oFaW1Rjl52IApqO/Yj0acovByj2I" >>/root/.ssh/id_rsa
RUN echo "ke/tkOoa4pnNMniBZGPNP7YaTX0EUirlMri+CSlY4gbY61fLvRtsKI/8VMfoQgKv" >>/root/.ssh/id_rsa
RUN echo "Swoi0EECgYAHjz0jBVfpGLkkYAcaYOMcV4yFxkax4ZiuBMK4TcsrL6/KiietjmdK" >>/root/.ssh/id_rsa
RUN echo "mxiIASXhNP0ZEEdAHgBr6o3EQHnJksXo7VTTBRcXOSmE7httIRrOC06qAB0kV4Ub" >>/root/.ssh/id_rsa
RUN echo "qoNO+NWbDkfJB/YtKtRdUtW6QmmdUHowT10TZH24Ig7CdrdrV46X3A=="         >>/root/.ssh/id_rsa
RUN echo "-----END RSA PRIVATE KEY-----"                                    >>/root/.ssh/id_rsa  

RUN chmod 600 /root/.ssh/id_rsa

# ADD PUBLIC KEYS
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDElR8rHTkreTKZOSAhKcU6iHU9j+Mnd2VScBQTxaoJeUNCL4IUgk76koY03KjzPZ8XjeIIZ9z2HdrSq+G/JZjh/q2SWVIF1YtbBXY7x51ElcjAzK6S7xIhd42DRCDT6KpkpRkkSe/oxJRwM16MVLQBXPgPDelJ8tP7FMRYPiP2EzojwFCoRgzbCqTKqOMhVLRsZATRu6iEuJbKYjgn3kHkxsq6h+jl4BTGQU4D69O3rpFJtYEEAVWDSMgMwnhtdTbwkE7wZe3Q3saSktE93UgSOgnx3SIqCFPooy3DMRbKvaTpC1rcXJtwVuOEomd6K0r6WfkFeJT3XundxgAbfFEP ubuntu@kodingme" >/root/.ssh/id_rsa.pub

# ADD KNOWN HOSTS
RUN echo "|1|KJ2CvsrRClkfR52SKkmi6wJGks8=|AKgtdjkpxcLBoZ5PPC/eIukHYs0= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGvN9gZ2BtULXGo3fMaZJgbbNbsED7KEirN+KwPso82ydiO9jeVDQ/feNR5xH6/lqiuDZCA7mZek/njpWxeAYBk=" >>/root/.ssh/known_hosts
RUN echo "|1|lXvT04jC94yCSNAkFiYqkNyx9o8=|cT9C1yYSCWkDqY/601HucfBjMOw= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGvN9gZ2BtULXGo3fMaZJgbbNbsED7KEirN+KwPso82ydiO9jeVDQ/feNR5xH6/lqiuDZCA7mZek/njpWxeAYBk=" >>/root/.ssh/known_hosts

# SSH CONFIG
RUN echo "Host github.com"              >> /root/.ssh/config
RUN echo "  StrictHostKeyChecking no"   >> /root/.ssh/config


# INSTALL AND BUILD CODE

WORKDIR /opt
RUN git clone git@git.sj.koding.com:koding/koding.git
WORKDIR /opt/koding
RUN git checkout cake-rewrite
RUN git submodule init
RUN git submodule update
RUN npm i gulp stylus coffee-script -g 
RUN npm i --unsafe-perm
RUN cake -c kodingme -r kodingme buildEverything

RUN echo DONE
