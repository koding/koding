/* 
 * File:   pty_process.hpp
 * Author: vic
 *
 * Created on January 5, 2012, 2:28 PM
 */

#ifndef PTY_PROCESS_HPP
#define PTY_PROCESS_HPP

#include <utility>
#include <stdexcept>
#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>
#include <signal.h>

namespace KFM{namespace Terminal{

    class CPtyProcess 
    {
    protected:
        int mFd;
        int mPid;

    public:

        CPtyProcess(const char *cmd, size_t rows, size_t cols);
        ~CPtyProcess();
        std::pair<int, int> getWindowSize();
        bool setWindowSize(size_t rows, size_t cols);
        int getFd();
        int getPid();
        bool kill(int signal = SIGTERM);
    protected:
        bool wait();
        void fork(const char *cmd, size_t rows, size_t cols);
    };

}} //end of namespace KFM::Terminal

#endif
