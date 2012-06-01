/* 
 * File:   terminal.hpp
 * Author: vic
 *
 * Created on January 6, 2012, 6:56 AM
 */

#ifndef TERMINAL_HPP
#define	TERMINAL_HPP

#include <boost/thread/mutex.hpp>

#include "pty_process.hpp"
#include "async_socket.hpp"
#include "screen_stream.hpp"
#include "screen.hpp"


namespace KFM{namespace Terminal{

    class CTerminal
    {
    private:
        boost::mutex mScreenLock;
        CScreen mScreen;
        pbe::Iconver<pbe::permissive,char,ucs4_char> mCharsetToUcs4;
        boost::function<void ()> mScreenReadyHandler;
        boost::function<void (std::string &)> mErrorHandler;
        CPtyProcess mProcess;
        CScreenStream mScreenStream;
        CAsyncSocket mSocket;
        bool mErrorFlag;
        
    public:
        CTerminal(boost::asio::io_service &service,const char *cmd,size_t rows,size_t cols,const char *charset="ASCII");
        ~CTerminal();
        void write(const char *,size_t);
        void write(std::string &);
        void parseScreen(boost::function<void (CScreen &)> );
        void resize(size_t,size_t);
        std::pair<size_t,size_t> getSize();
        void bindScreenReady(boost::function<void ()>);
        void bindError(boost::function<void (std::string &)>);
        bool hasError();
        void resetError();
        size_t numRows() ;
        size_t numCols() ;
        void kill();
    protected:
        void readResultHandler(const char *, const size_t);
        void errorHandler(std::string &str);
        
    };
    
    

    
}} //end of namespace KFM::Terminal


#endif	/* TERMINAL_HPP */

