// references:
// https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapcoreheader

#include <iostream>

// Note: Represented in little-endian format

const char BITMAPFILEHEADER[] = {
  'B', 'M', // BM header
  '\x00', '\x00', '\x00', '\x00', // size of whole file // TODO
  '\x00', '\x00', '\x00', '\x00', // Application ID = 0

  '\x00', '\x00', '\x00', '\x00', // offset of pixel array // TODO

}; // 14 bytes

const char DIBHEADER[] = {
  '\x28', '\x00', '\x00', '\x00', // 40 bytes in DIB header
  '\x40', '\x01', '\x00', '\x00', // 320 px width
  '\x10', '\xff', '\xff', '\xff', // -240 px height
  '\x01', '\x00',                 // 1 color plane
  '\x08', '\x00',                 // 8 bits per pixel
  '\x00', '\x00', '\x00', '\x00', // no compression
  '\x00', '\x00', '\x00', '\x00', // image size (give 0 since uncompressed)
  '\x13', '\x0b', '\x00', '\x00', // horizontal and vertical print
  '\x13', '\x0b', '\x00', '\x00', // resolutions. Set to 2835px per metre
  '\x00', '\x01', '\x00', '\x00', // 256 colors in palette
  '\x00', '\x00', '\x00', '\x00', // 0 for important colors

}; // 40 bytes

int main() {

  // print File header
  for (int i=0; i<sizeof(BITMAPFILEHEADER); i++) {
    std::cout << BITMAPFILEHEADER[i];
  }

  // print DIB header
  for (int i=0; i<sizeof(DIBHEADER); i++) {
    std::cout << DIBHEADER[i];
  }




}