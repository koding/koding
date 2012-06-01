/* 
 * File:   util.hpp
 * Author: vic
 *
 * Created on January 7, 2012, 2:42 PM
 */

#ifndef IO_HPP
#define	IO_HPP

#include <iostream>
#include "screen.hpp"

std::ostream & operator << (std::ostream &os,KFM::Terminal::CScreen &screen)
{
    os<<std::endl<<"***************** Screen *******************"<<std::endl;
    os<<"* Cursor {row:"<<screen.getCursorRow()<<",col:"<<screen.getCursorCol()<<"} ";
    os<<(screen.isCursorVisible()?"visible":"not visible")<<std::endl;
    os<<"* size {rows:"<<screen.numRows()<<",cols:"<<screen.numCols()<<"}"<<std::endl;
    os<<"********************************************"<<std::endl;
    std::pair<size_t,size_t> cursor=screen.getCursor();
    for(int r=0;r<screen.numRows();r++)
    {
        std::cout<<'|';
        for(int c=0;c<screen.numCols();c++)
        {
            if((r==cursor.first)&&(c==cursor.second))
            {
                std::cout<<"_";
            }
            else
            {
                Cell &cell=screen.getCell(r,c);
                std::cout<<(char)cell.c;
            }
           
        }
        std::cout<<'|'<<std::endl;
    }
    std::cout<<std::endl<<"********************************************"<<std::endl<<std::flush;
}

#endif	/* IO_HPP */

