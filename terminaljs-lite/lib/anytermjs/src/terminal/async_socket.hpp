/* 
 * File:   async_socket.hpp
 * Author: vic
 *
 * Created on January 5, 2012, 2:49 PM
 */

#ifndef ASYNC_SOCKET_HPP
#define	ASYNC_SOCKET_HPP

#include <boost/asio.hpp>
#include <boost/function.hpp>
#include <boost/bind.hpp>


namespace KFM{namespace Terminal{

    class CAsyncSocket
    {
    private:
        boost::asio::io_service &mIOService;
        boost::asio::posix::stream_descriptor mStream;
        boost::function<void (const char *,const size_t)>  mReadCallback;
        boost::function<void (std::string &)>  mErrorCallback;
        boost::asio::streambuf mBuffer;
    public :
        CAsyncSocket(boost::asio::io_service &ioService);
        ~CAsyncSocket();
        void init(int fd,boost::function<void (const char *,const size_t)> read_callback,boost::function<void  (std::string &)> error_callback);
        void write(const char *b,const size_t sz);
        void cancel();
    private:
        void readSome();
        void handleReadResult(boost::system::error_code error,const size_t bytes);
        void handleWriteResult(boost::system::error_code error,const size_t bytes);
    };
}}


#endif	/* ASYNC_SOCKET_HPP */

