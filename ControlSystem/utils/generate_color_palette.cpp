// references:
// https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapcoreheader

#include <iostream>
#include <string>


int main() {


  /**
   * print pixel array:
   * 
   * 1 byte B, then G, then R, then zero
   * 
   * RGB values using 3-3-2 bits to get 8-8-4 colors
   * 
   */

  for (int r=0; r<8; r++) {
    for (int g=0; g<8; g++) {
      for (int b=0; b<4; b++) {
        std::string red, green, blue;
        // select red
        switch (r)
        {
        case 0 : red = "\'\\x00\'"; break;
        case 1 : red ="\'\\x24\'"; break;
        case 2 : red ="\'\\x49\'"; break;
        case 3 : red ="\'\\x6d\'"; break;
        case 4 : red ="\'\\x92\'"; break;
        case 5 : red ="\'\\xb6\'"; break;
        case 6 : red ="\'\\xdb\'"; break;
        case 7 : red ="\'\\xff\'"; break;
        }

        // select green
        switch (g)
        {
        case 0 : green ="\'\\x00\'"; break;
        case 1 : green ="\'\\x24\'"; break;
        case 2 : green ="\'\\x49\'"; break;
        case 3 : green ="\'\\x6d\'"; break;
        case 4 : green ="\'\\x92\'"; break;
        case 5 : green ="\'\\xb6\'"; break;
        case 6 : green ="\'\\xdb\'"; break;
        case 7 : green ="\'\\xff\'"; break;
        }

        // select blue
        switch (b)
        {
        case 0 : blue ="\'\\x00\'"; break;
        case 1 : blue ="\'\\x55\'"; break;
        case 2 : blue ="\'\\xaa\'"; break;
        case 3 : blue ="\'\\xff\'"; break;
        }

        std::cout << blue << ", " << green << ", " << red << ", " << "\'\\x00\'" << ", " << std::endl;
      }
    }
  }


}