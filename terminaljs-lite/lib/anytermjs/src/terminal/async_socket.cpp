#include "async_socket.hpp"
#include <fcntl.h>
namespace KFM{namespace Terminal{
    
    CAsyncSocket::CAsyncSocket(boost::asio::io_service &ioService) : mIOService(ioService) , mStream(ioService)
    {}
    CAsyncSocket::~CAsyncSocket()
    {
        mStream.cancel();
    }
    void CAsyncSocket::cancel()
    {
        mStream.cancel();
    }
    void CAsyncSocket::init(int fd,boost::function<void (const char*,const size_t)> readCallback,boost::function<void (std::string &)> errorCallback)
    {
        fcntl(fd, F_SETFL, O_NONBLOCK);  // set to non-blocking
        mStream.assign(fd);
        mReadCallback=readCallback;
        mErrorCallback=errorCallback;
        readSome();
    }
    void CAsyncSocket::write(const char *p,const size_t sz)
    {
        boost::asio::async_write(mStream,boost::asio::buffer(p,sz),boost::bind(&CAsyncSocket::handleWriteResult,this,boost::asio::placeholders::error,boost::asio::placeholders::bytes_transferred));
    }
    void CAsyncSocket::handleWriteResult(boost::system::error_code ec,const size_t sz)
    {
        if(ec&&(ec!=boost::asio::error::operation_aborted))
        {
            std::string error=ec.message();
            mErrorCallback(error);
            
        }
    }
    void CAsyncSocket::readSome()
    {
        boost::asio::async_read(mStream,mBuffer,boost::asio::transfer_at_least(1),boost::bind(&CAsyncSocket::handleReadResult,this,boost::asio::placeholders::error,boost::asio::placeholders::bytes_transferred));
    }
    void CAsyncSocket::handleReadResult(boost::system::error_code ec,const size_t sz)
    {
        if(ec)
        {
            if(ec!=boost::asio::error::operation_aborted)
            {
                std::string error=ec.message();
                if(mErrorCallback)
                {
                        mErrorCallback(error);
                }
            }
        }
        else
        {
            if(sz>0)
            {
                const char *p=boost::asio::buffer_cast<const char*>(mBuffer.data());
                if(mReadCallback)
                {
                        mReadCallback(p,sz);
                }
                mBuffer.consume(sz);
                readSome();
            }
        }
    }

}} // end of namespace KFM::Terminal
