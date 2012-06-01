// author: Victor Bucataru
// copyright kodingen 2012

#ifndef __KFM_LOG_LOG_HPP__
#define __KFM_LOG_LOG_HPP__

#include <cassert>
#include <iostream>
#include <fstream>
#include <string>
#include <typeinfo>

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


#if defined( _KFM_LOG_ENABLED_) && (!_KFM_LOG_ENABLED_)
#undef _KFM_LOG_ENABLED_
#endif

namespace KFM{namespace LOG{

    enum severity_level
	{
    	debug,
    	info,
    	warning,
    	error
	};

    template< typename CharT, typename TraitsT >
    std::basic_ostream< CharT, TraitsT >& operator<< (std::basic_ostream< CharT, TraitsT >& strm, severity_level lvl)
    {
		  static const char* const str[] =
		 {
		    "DBG",
		    "INF",
		    "WRN",
		    "ERR"
		 };
		if (static_cast< std::size_t >(lvl) < (sizeof(str) / sizeof(*str)))
		    strm << str[lvl];
		else
		    strm << static_cast< int >(lvl);
		return strm;
    }
    typedef boost::log::sources::severity_logger_mt< severity_level > kfm_logger;
    extern kfm_logger __logger;

}} //end of namespace KFM::LOG

#ifdef _KFM_LOG_ENABLED_



#define KFM_LOG(__level,x)                                                          \
        try                                                                         \
        {                                                                           \
             BOOST_LOG_SEV(KFM::LOG::__logger,__level)<<"[th:"<<boost::this_thread::get_id()<<"] ["<<__PRETTY_FUNCTION__<<"] "<<x;\
        }                                                                           \
        catch(...)                                                                  \
        {}

#define KFM_LOG_INIT_FILE(filename)\
    	boost::shared_ptr< boost::log::attribute > pTimeStamp(new boost::log::attributes::local_clock());\
    	boost::log::core::get()->add_global_attribute("TimeStamp", pTimeStamp);   \
        boost::log::init_log_to_file                                                     \
        (                                                                                \
                boost::log::keywords::file_name = ""filename,                       \
                boost::log::keywords::format = boost::log::formatters::stream\
				<< boost::log::formatters::date_time< boost::posix_time::ptime > ("TimeStamp", "%H:%M:%S") \
				<<boost::log::formatters::if_(boost::log::filters::has_attr("Tag"))[boost::log::formatters::stream << boost::log::formatters::attr< std::string >("Tag")<< "] "]\
                <<" ["<<boost::log::formatters::attr< KFM::LOG::severity_level >("Severity", std::nothrow)<<"] "\
                << boost::log::formatters::message()\
        )

#define KFM_LOG_SET_LEVEL(x)                                                                          \
        boost::log::core::get()->set_filter                                                           \
        (                                                                                             \
                boost::log::filters::attr<KFM::LOG::severity_level >("Severity") >= x     \
        )  

#define KFM_LOG_CTX(x) BOOST_LOG_SCOPED_THREAD_TAG("Tag", std::string, x)

#else
//just ignore
#define KFM_LOG(__level,x)
#define KFM_LOG_INIT_FILE(name)
#define KFM_LOG_SET_LEVEL(x)
#define KFM_LOG_CTX(x)
#endif






#define KFM_LOG_DBG_LEVEL KFM::LOG::severity_level::debug
#define KFM_LOG_INF_LEVEL KFM::LOG::severity_level::info
#define KFM_LOG_WRN_LEVEL KFM::LOG::severity_level::warning
#define KFM_LOG_ERR_LEVEL KFM::LOG::severity_level::error



#define KFM_LOG_DBG(x) KFM_LOG(KFM::LOG::debug, x)
#define KFM_LOG_INF(x) KFM_LOG(KFM::LOG::info, x)
#define KFM_LOG_WRN(x) KFM_LOG(KFM::LOG::warning, x)
#define KFM_LOG_ERR(x) KFM_LOG(KFM::LOG::error, x)

#endif //#ifndef __LOG_LOG_HPP__
