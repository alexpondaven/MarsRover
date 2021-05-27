#define FRAME_SIZE_BYTES 76800// supposed to be 76800

typedef struct {
  char BITMAPFILEHEADER[14];
  char DIBHEADER[40];
  char COLOR_PALETTE[1024];
  
  char FRAME_BUFFER[FRAME_SIZE_BYTES];
  char padding[2];
} bitmap_t;
