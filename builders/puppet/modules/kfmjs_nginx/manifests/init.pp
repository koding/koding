#
# Module: kfmjs_nginx
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: kfmjs_nginx
#
#
class kfmjs_nginx {
    include kfmjs_nginx::install, kfmjs_nginx::config, kfmjs_nginx::service, kfmjs_nginx::repo
}
