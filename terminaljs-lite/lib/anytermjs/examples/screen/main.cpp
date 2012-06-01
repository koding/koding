#define _KFM_LOG_ENABLED_ 0
#include "log.hpp"
#include "screen.hpp"
#include "screen_stream.hpp"
#include "common/io.hpp"
#include <iostream>



int main()
{
	KFM_LOG_INIT_FILE("terminal.log");
  Attributes attr;
  KFM::Terminal::CScreen screen(10,100);
  int i,j;
  std::cout<<"\ngetCell overflow "<<std::flush;

  for(i=0;i<100;i++)
  {
    for(j=0;j<1000;j++)
    {
      screen.getCell(i,j);
    }
  }

  std::cout<<"\nsetCursorRow overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.setCursorRow(i);
    screen.pushChar(L'A',attr);
  }

  std::cout<<"\nsetCursorCol overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.setCursorCol(i);
    screen.pushChar(L'A',attr);
  }
  
  std::cout<<"\nsetCursor overflow"<<std::flush;
  for(i=0;i<1000;i++)
  { 
    for(j=0;j<1000;j++)
    {
      screen.setCursor(i,j);
      screen.pushChar(L'A',attr);
    }
  }

  std::cout<<"\nsetScrollingRegion overflow "<<std::flush;
  for(i=0;i<101;i++)
  {
    for(j=0;j<1000;j++)
    {  
      screen.setScrollingRegion(i,j);
      screen.pushChar(L'A',attr);
    }
  }

  std::cout<<"\nscrollUp overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.scrollUp(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\nscrollDown overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.scrollDown(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\ncursorUp overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.cursorUp(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\ncursorDown overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.cursorDown(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\ncursorRight overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.cursorRight(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\ncursorLeft overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.cursorLeft(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\nclearRow overflow"<<std::flush;
  for(i=0;i<1000;i++)
  {
    screen.clearRow(i);
    screen.pushChar(L'A',attr);
  }
  std::cout<<"\nresizing "<<std::flush;
  for(i=1;i<100;i++)
  {
    for(j=1;j<100;j++)
    {
      screen.setSize(i,j);
      screen.pushChar(L'A',attr);
    }
  }
  screen.pushChar(L'A',attr);
	/*KFM_LOG_INIT_FILE("terminal.log");
/*    KFM::Terminal::CScreen screen(50,100);
    KFM::Terminal::CScreenStream screen_stream(screen);
    ucs4_string str=L"this is a test :/> ";
    for(int i=0;i<100000;i++)
    {
    	screen_stream.write(str);
    }
    std::cout<<screen;
    std::cout<<std::endl<<"scrolling up"<<std::endl;
    for(int i=0;i<100000;i++)
    {
    	screen.scrollUp(4);
    }
    std::cout<<screen;
    std::cout<<std::endl<<"scrolling down"<<std::endl;
	for(int i=0;i<99;i++)
	{
		screen.scrollDown(6);
	}
    std::cout<<screen;
    std::cout<<std::endl<<"resizing window to {20,70}"<<std::endl;
    screen.setSize(20,70);
    std::cout<<screen;
    std::cout<<std::endl<<"resizing window to {10,10}"<<std::endl;
    screen.setSize(10,10);
    std::cout<<screen;
    std::cout<<std::endl<<"scrolling up"<<std::endl;
    for(int i=0;i<100000;i++)
    {
    	screen.scrollUp(4);
    }
    std::cout<<screen;
    std::cout<<std::endl<<"scrolling down"<<std::endl;
	for(int i=0;i<99;i++)
	{
		screen.scrollDown(6);
	}
	screen.setScrollingRegion(5,10);
    std::cout<<std::endl<<"scrolling up"<<std::endl;
    for(int i=0;i<100000;i++)
    {
    	screen.scrollUp(4);
    }
    std::cout<<screen;
    std::cout<<std::endl<<"scrolling down"<<std::endl;
	for(int i=0;i<99;i++)
	{
		screen.scrollDown(6);
	}
*/
    return 0;
}
