#include "log.hpp"
#include <boost/shared_ptr.hpp>
#include <boost/make_shared.hpp>

#include <boost/log/common.hpp>
#include <boost/log/formatters.hpp>
#include <boost/log/filters.hpp>

#include <boost/log/utility/init/to_file.hpp>
#include <boost/log/utility/init/to_console.hpp>
#include <boost/log/utility/init/common_attributes.hpp>

#include <boost/log/attributes/timer.hpp>
#include <boost/thread.hpp>


namespace KFM{namespace LOG{
    
    kfm_logger __logger;

}} //end of namespace KFM::LOG
