#define _KFM_LOG_ENABLED_ 0
#include "log.hpp"

#include "common/io.hpp"
#include <iostream>
#include <boost/thread.hpp>
#include <sstream>
#include <string>
#include "terminal.hpp"


struct ScreenParser
{
    KFM::Terminal::CTerminal &terminal;
    ScreenParser(KFM::Terminal::CTerminal &t) : terminal(t)
    {}
    void parse()
    {
        terminal.parseScreen<void>(boost::bind(&ScreenParser::print,this,_1));
    }
    void print(KFM::Terminal::CScreen & scr)
    {
        std::cout<<std::endl<<"<parser>"<<std::endl;
        std::cout<<scr;
        std::cout<<std::endl<<"</parser>"<<std::endl<<std::flush;
    }
};


void ErrorHandler(std::string &str)
{
   std::cerr<<std::endl<<"############### ERROR : "<<str<<std::endl<<std::flush;

};

boost::asio::io_service io_service;

void ioParser()
{
    std::cout<<"\nrunning parser"<<std::flush;
    boost::asio::io_service::work work(io_service);
    io_service.run();
    std::cout<<"\ncomplete...."<<std::flush;
}

void gracefullExit()
{
    std::cout<<"\nexiting ..."<<std::flush;
    io_service.stop();
}

int main()
{
  KFM_LOG_INIT_FILE("terminal.log");
    boost::thread thread(boost::bind(ioParser));
    KFM::Terminal::CTerminal terminal(io_service,"/bin/bash",20,30);
    ScreenParser parser(terminal);
    terminal.bindError(boost::bind(&ErrorHandler,_1));
    terminal.bindScreenReady(boost::bind(&ScreenParser::parse,&parser));
    terminal.write("vi\n",4);
 
   
    terminal.write("i\n",2);
  for(int i=0;i<100;i++)
  {
    std::stringstream ss;
    ss<<"test string ["<<i<<"]\n\n";
    std::string str=ss.str();
    terminal.write(str.c_str(),str.length());
    size_t rows=rand()%200;
    size_t cols=rand()%200;
    std::cout<<"\nresizing screen to {rows:"<<rows<<",cols:"<<cols<<"}"<<std::flush;
    terminal.resize(rows,cols);
    sleep(1);
  }
  boost::asio::deadline_timer timer(io_service);
    timer.expires_from_now(boost::posix_time::seconds(10));
  timer.async_wait(boost::bind(gracefullExit));
    thread.join();
    return 0;
}

