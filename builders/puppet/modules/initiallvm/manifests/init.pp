#
# Module: initiallvm
#
#  Created by  on 2012-02-14.
#  Copyright (c) 2012 Koding. All rights reserved.
#

# Class: initiallvm
#
#

# Class: initiallvm
#
#
class initiallvm {
    include initiallvm::xfs_packages, initiallvm::create_fs,initiallvm::mount
}
