#
# Module: pure-ftpd_tls
#
#  Created by  on 2012-03-02.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: pure-ftpd_tls
#
#
class pure-ftpd_tls {
    include pure-ftpd_tls::install
    include pure-ftpd_tls::config
    include pure-ftpd_tls::service
    include pure-ftpd_tls::authapp
    include pure-ftpd_tls::scripts
}
