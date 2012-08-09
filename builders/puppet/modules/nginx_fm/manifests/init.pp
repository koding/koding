#
# Module: nginx_fm
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: nginx_fm
#
#
class nginx_fm {
    include nginx_fm::install, nginx_fm::config, nginx_fm::service, nginx_fm::repo
}
