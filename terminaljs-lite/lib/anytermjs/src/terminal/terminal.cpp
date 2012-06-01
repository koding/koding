#include <sys/syslog.h>
#include "defines.hpp"
#include "terminal.hpp"
#define _KFM_LOG_ENABLED_ 0
#include "log/log.hpp"
#include <sstream>

std::ostream & operator <<(std::ostream &os, KFM::Terminal::CScreen &scr)
{
	size_t rows = scr.numRows();
	size_t cols = scr.numCols();
	for(int i=0;i<rows;i++)
	{
		for(int j=0;j<cols;j++)
		{
			os<<(char)scr.getCell(i,j).c;
		}
		os<<std::endl;
	}
	return os;
}

namespace KFM{namespace Terminal{
    
    CTerminal::CTerminal(boost::asio::io_service &service,const char *cmd,size_t rows,size_t cols,const char *charset) : 
        mProcess(cmd,rows,cols),mSocket(service), mScreen(rows,cols), mScreenStream(mScreen),
        mCharsetToUcs4(charset,UCS4_NATIVE),mErrorFlag(false)
    {
        mSocket.init(mProcess.getFd(),boost::bind(&CTerminal::readResultHandler,this,_1,_2),boost::bind(&CTerminal::errorHandler,this,_1));
    }
    
    CTerminal::~CTerminal()
    {
        KFM_LOG_DBG("destructor called");
        mSocket.cancel();
    }
    
    void CTerminal::parseScreen(boost::function<void(CScreen &)> handler)
    {
        boost::mutex::scoped_lock lock(mScreenLock);
        handler(mScreen);
    }
    void CTerminal::bindScreenReady(boost::function<void ()> callback)
    {
        KFM_LOG_DBG("bind screen ready event");
        mScreenReadyHandler=callback;
    }
    void CTerminal::bindError(boost::function<void (std::string&)> callback)
    {
       KFM_LOG_DBG("bind error event");
        mErrorHandler=callback;
    }
    void CTerminal::errorHandler(std::string& str)
    {
        KFM_LOG_WRN("error occurred: "<<str);
        mErrorFlag=true;
        if(mErrorHandler)
        {
            mErrorHandler(str);
        }
    }
    bool CTerminal::hasError()
    {
        return mErrorFlag;
    }
    
    void CTerminal::resetError()
    {
        KFM_LOG_INF("error is reseted");
        mErrorFlag=false;
    }
    
    void CTerminal::readResultHandler(const char *p, const size_t sz)
    {
    	KFM_LOG_DBG("**********************************************");
    	std::string s(p,sz);
        KFM_LOG_INF("screen update : "<<s);
        ucs4_string str=mCharsetToUcs4(p,sz);
        {
        boost::mutex::scoped_lock lock(mScreenLock);
        std::stringstream ss;
        ss<<mScreen;
        KFM_LOG_DBG("screen before update : "<<std::endl<<ss.str());
        ss.str("");
        mScreenStream.write(str);
        ss<<mScreen;
        KFM_LOG_DBG("screen after update : "<<std::endl<<ss.str());
        KFM_LOG_DBG("**********************************************");
        }
        if(mScreenReadyHandler)
        {
            mScreenReadyHandler();
        }
    }
    
    void CTerminal::write(const char* p, size_t sz)
    {
        KFM_LOG_INF("writing something to screen ["<<p<<"]");
        mSocket.write(p,sz);
    }
    void CTerminal::write(std::string& str)
    {
        write(str.c_str(),str.size());
    }
    
    std::pair<size_t,size_t> CTerminal::getSize()
    {
		boost::mutex::scoped_lock lock(mScreenLock);
        std::pair<size_t,size_t> res = mScreen.getSize();
        return res;
    }
    
    void CTerminal::resize(size_t rows,size_t cols)
    {
        KFM_LOG_DBG("resize called {rows:"<<rows<<",cols:"<<cols<<"}");
        boost::mutex::scoped_lock lock(mScreenLock);
        if(rows<10) rows=10;
        if(cols<10) cols=10;
        mScreen.setSize(rows,cols);
        mProcess.setWindowSize(rows,cols);
    }
    
    size_t CTerminal::numRows()
    {
        boost::mutex::scoped_lock lock(mScreenLock);
        size_t rows= mScreen.numRows();
        return rows;
    }
    size_t CTerminal::numCols()
    {
        boost::mutex::scoped_lock lock(mScreenLock);
        size_t cols= mScreen.numCols();
        return cols;
    }
    
    void CTerminal::kill()
    {
        KFM_LOG_INF("killing terminal");
        mProcess.kill();
        mSocket.cancel();
    }
    
    
}}// end of namespace KFM::Terminal
