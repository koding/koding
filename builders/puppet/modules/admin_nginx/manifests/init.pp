#
# Module: nginx
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: nginx
#
#
class admin_nginx {
    include admin_nginx::install, admin_nginx::config, admin_nginx::service, admin_nginx::repo
}
