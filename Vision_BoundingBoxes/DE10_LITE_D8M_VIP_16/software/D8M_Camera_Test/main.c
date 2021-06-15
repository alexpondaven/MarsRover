#include "system.h"
#include <stdlib.h>
#include <stdio.h>
#include "I2C_core.h"
#include "terasic_includes.h"
#include "mipi_camera_config.h"
#include "mipi_bridge_config.h"

#include "auto_focus.h"

#include <fcntl.h>
#include <unistd.h>

#include <math.h>

//EEE_IMGPROC defines
#define RED_MSG_START ('R'<<16 | 'B'<<8 | 'B')
#define PINK_MSG_START ('P'<<16 | 'B'<<8 | 'B')
#define YELLOW_MSG_START ('Y'<<16 | 'B'<<8 | 'B')
#define GREEN_MSG_START ('G'<<16 | 'B'<<8 | 'B')
#define BLUE_MSG_START ('B'<<16 | 'B'<<8 | 'B')

//offsets
#define EEE_IMGPROC_STATUS 0
#define EEE_IMGPROC_MSG 1
#define EEE_IMGPROC_ID 2
//#define EEE_IMGPROC_BBCOL 3
#define COL_SEL 3
//#define EEE_IMGPROC_CONTRAST 4
//#define EEE_IMGPROC_RED_THRESH 6
//#define EEE_IMGPROC_COL_DETECT 5
#define EEE_IMGPROC_DIST_THRESH 7

#define HUE 4
#define SAT 5
#define VAL 6


#define EXPOSURE_INIT 0x002400
#define EXPOSURE_STEP 0x500
#define GAIN_INIT 0x500 // or 500
#define GAIN_STEP 0x100
#define DEFAULT_LEVEL 3

#define MIPI_REG_PHYClkCtl		0x0056
#define MIPI_REG_PHYData0Ctl	0x0058
#define MIPI_REG_PHYData1Ctl	0x005A
#define MIPI_REG_PHYData2Ctl	0x005C
#define MIPI_REG_PHYData3Ctl	0x005E
#define MIPI_REG_PHYTimDly		0x0060
#define MIPI_REG_PHYSta			0x0062
#define MIPI_REG_CSIStatus		0x0064
#define MIPI_REG_CSIErrEn		0x0066
#define MIPI_REG_MDLSynErr		0x0068
#define MIPI_REG_FrmErrCnt		0x0080
#define MIPI_REG_MDLErrCnt		0x0090

void mipi_clear_error(void){
	MipiBridgeRegWrite(MIPI_REG_CSIStatus,0x01FF); // clear error
	MipiBridgeRegWrite(MIPI_REG_MDLSynErr,0x0000); // clear error
	MipiBridgeRegWrite(MIPI_REG_FrmErrCnt,0x0000); // clear error
	MipiBridgeRegWrite(MIPI_REG_MDLErrCnt, 0x0000); // clear error

  	MipiBridgeRegWrite(0x0082,0x00);
  	MipiBridgeRegWrite(0x0084,0x00);
  	MipiBridgeRegWrite(0x0086,0x00);
  	MipiBridgeRegWrite(0x0088,0x00);
  	MipiBridgeRegWrite(0x008A,0x00);
  	MipiBridgeRegWrite(0x008C,0x00);
  	MipiBridgeRegWrite(0x008E,0x00);
  	MipiBridgeRegWrite(0x0090,0x00);
}

void mipi_show_error_info(void){

	alt_u16 PHY_status, SCI_status, MDLSynErr, FrmErrCnt, MDLErrCnt;

	PHY_status = MipiBridgeRegRead(MIPI_REG_PHYSta);
	SCI_status = MipiBridgeRegRead(MIPI_REG_CSIStatus);
	MDLSynErr = MipiBridgeRegRead(MIPI_REG_MDLSynErr);
	FrmErrCnt = MipiBridgeRegRead(MIPI_REG_FrmErrCnt);
	MDLErrCnt = MipiBridgeRegRead(MIPI_REG_MDLErrCnt);
	printf("PHY_status=%xh, CSI_status=%xh, MDLSynErr=%xh, FrmErrCnt=%xh, MDLErrCnt=%xh\r\n", PHY_status, SCI_status, MDLSynErr,FrmErrCnt, MDLErrCnt);
}

void mipi_show_error_info_more(void){
    printf("FrmErrCnt = %d\n",MipiBridgeRegRead(0x0080));
    printf("CRCErrCnt = %d\n",MipiBridgeRegRead(0x0082));
    printf("CorErrCnt = %d\n",MipiBridgeRegRead(0x0084));
    printf("HdrErrCnt = %d\n",MipiBridgeRegRead(0x0086));
    printf("EIDErrCnt = %d\n",MipiBridgeRegRead(0x0088));
    printf("CtlErrCnt = %d\n",MipiBridgeRegRead(0x008A));
    printf("SoTErrCnt = %d\n",MipiBridgeRegRead(0x008C));
    printf("SynErrCnt = %d\n",MipiBridgeRegRead(0x008E));
    printf("MDLErrCnt = %d\n",MipiBridgeRegRead(0x0090));
    printf("FIFOSTATUS = %d\n",MipiBridgeRegRead(0x00F8));
    printf("DataType = 0x%04x\n",MipiBridgeRegRead(0x006A));
    printf("CSIPktLen = %d\n",MipiBridgeRegRead(0x006E));
}



bool MIPI_Init(void){
	bool bSuccess;


	bSuccess = oc_i2c_init_ex(I2C_OPENCORES_MIPI_BASE, 50*1000*1000,400*1000); //I2C: 400K
	if (!bSuccess)
		printf("failed to init MIPI- Bridge i2c\r\n");

    usleep(50*1000);
    MipiBridgeInit();

    usleep(500*1000);

//	bSuccess = oc_i2c_init_ex(I2C_OPENCORES_CAMERA_BASE, 50*1000*1000,400*1000); //I2C: 400K
//	if (!bSuccess)
//		printf("failed to init MIPI- Camera i2c\r\n");

    MipiCameraInit();
    MIPI_BIN_LEVEL(DEFAULT_LEVEL);
//    OV8865_FOCUS_Move_to(340);

//    oc_i2c_uninit(I2C_OPENCORES_CAMERA_BASE);  // Release I2C bus , due to two I2C master shared!


 	usleep(1000);


//    oc_i2c_uninit(I2C_OPENCORES_MIPI_BASE);

	return bSuccess;
}




int main()
{
	fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);


  printf("DE10-LITE D8M VGA Demo\n");
  printf("Imperial College EEE2 Project version\n");
  IOWR(MIPI_PWDN_N_BASE, 0x00, 0x00);
  IOWR(MIPI_RESET_N_BASE, 0x00, 0x00);

  usleep(2000);
  IOWR(MIPI_PWDN_N_BASE, 0x00, 0xFF);
  usleep(2000);
  IOWR(MIPI_RESET_N_BASE, 0x00, 0xFF);

  printf("Image Processor ID: %x\n",IORD(0x42000,EEE_IMGPROC_ID));
  //printf("Image Processor ID: %x\n",IORD(EEE_IMGPROC_0_BASE,EEE_IMGPROC_ID)); //Don't know why this doesn't work - definition is in system.h in BSP


  usleep(2000);


  // MIPI Init
   if (!MIPI_Init()){
	  printf("MIPI_Init Init failed!\r\n");
  }else{
	  printf("MIPI_Init Init successfully!\r\n");
  }

//   while(1){
 	    mipi_clear_error();
	 	usleep(50*1000);
 	    mipi_clear_error();
	 	usleep(1000*1000);
	    mipi_show_error_info();
//	    mipi_show_error_info_more();
	    printf("\n");
//   }


#if 0  // focus sweep
	    printf("\nFocus sweep\n");
 	 	alt_u16 ii= 350;
 	    alt_u8  dir = 0;
 	 	while(1){
 	 		if(ii< 50) dir = 1;
 	 		else if (ii> 1000) dir =0;

 	 		if(dir) ii += 20;
 	 		else    ii -= 20;

 	    	printf("%d\n",ii);
 	     OV8865_FOCUS_Move_to(ii);
 	     usleep(50*1000);
 	    }
#endif






    //////////////////////////////////////////////////////////
        alt_u16 bin_level = DEFAULT_LEVEL;
        alt_u8  manual_focus_step = 10;
        alt_u16  current_focus = 300;
        int boundingBoxColour = 0;
		alt_u32 exposureTime = EXPOSURE_INIT;
		alt_u16 gain = GAIN_INIT;

		OV8865SetExposure(exposureTime);
		OV8865SetGain(gain);
        Focus_Init();


        //init UART for esp
//        FILE* fp;
//        fp = fopen ("/dev/uart_esp", "r+"); //open file for read/write UART_ESP_NAME = "/dev/uart_esp"

//		if (fp==NULL){
//			printf("didn't open");
//			fp = fopen ("/dev/uart_esp", "r+");
//
//		} else {
//			printf("opened");
//		}

        FILE* ser = fopen("/dev/uart_esp", "rb+");
		if(ser){
			printf("Opened UART\n");
		} else {
			printf("Failed to open UART\n");
			while (1);
		}


  while(1){

       // touch KEY0 to trigger Auto focus
	   if((IORD(KEY_BASE,0)&0x03) == 0x02){

    	   current_focus = Focus_Window(320,240);
       }
	   // touch KEY1 to ZOOM
	         if((IORD(KEY_BASE,0)&0x03) == 0x01){
	      	   if(bin_level == 3 )bin_level = 1;
	      	   else bin_level ++;
	      	   printf("set bin level to %d\n",bin_level);
	      	   MIPI_BIN_LEVEL(bin_level);
	      	 	usleep(500000);

	         }


	#if 0
       if((IORD(KEY_BASE,0)&0x0F) == 0x0E){

    	   current_focus = Focus_Window(320,240);
       }

       // touch KEY1 to trigger Manual focus  - step
       if((IORD(KEY_BASE,0)&0x0F) == 0x0D){

    	   if(current_focus > manual_focus_step) current_focus -= manual_focus_step;
    	   else current_focus = 0;
    	   OV8865_FOCUS_Move_to(current_focus);

       }

       // touch KEY2 to trigger Manual focus  + step
       if((IORD(KEY_BASE,0)&0x0F) == 0x0B){
    	   current_focus += manual_focus_step;
    	   if(current_focus >1023) current_focus = 1023;
    	   OV8865_FOCUS_Move_to(current_focus);
       }

       // touch KEY3 to ZOOM
       if((IORD(KEY_BASE,0)&0x0F) == 0x07){
    	   if(bin_level == 3 )bin_level = 1;
    	   else bin_level ++;
    	   printf("set bin level to %d\n",bin_level);
    	   MIPI_BIN_LEVEL(bin_level);
    	 	usleep(500000);

       }
	#endif
    //Read messages from the image processor and print them on the terminal
	while ((IORD(0x42000,EEE_IMGPROC_STATUS)>>8) & 0xff) { 	//Find out if there are words to read
		int word = IORD(0x42000,EEE_IMGPROC_MSG); 			//Get next word from message buffer

		if (word==RED_MSG_START || word==PINK_MSG_START || word==YELLOW_MSG_START
			|| word==GREEN_MSG_START || word==BLUE_MSG_START){	//Newline on message identifier
		   printf("\n");
		   //send new line through uart
		   int nl = '\n';
		   if (fwrite(&nl, 1, 1, ser) != 1)
		   		   printf("Error writing to UART");
		}
		if (fwrite(&word, 4, 1, ser) != 1) // write the word to the esp
			printf("Error writing to UART");
		printf("%08x ",word);
	}

       //Update the bounding box colour - cycles from blue (0000ff) to green (00ff00)
       //boundingBoxColour = ((boundingBoxColour + 1) & 0xff);
       //IOWR(0x42000, EEE_IMGPROC_BBCOL, (boundingBoxColour << 8) | (0xff - boundingBoxColour));

       //Process input commands

//		  char in;
//		  //reading through uart:
////		  if (fread(&in,1,1,ser) != 1)
////			  printf("Error reading from UART");
//
//		  //read until newline
//		  do {
//			  printf("\nreading");
//
//
//			  fread(&in,1,1,ser);
//			  printf("in= %c",in);
//		  }
//		  while (in!='\n');
//
//
//		  char colour,type,option,value;
//		  char hsv_struct[4];
//		  int col_sel,hsv_sel;
//		  int hue_min,hue_max,sat_min,sat_max,val_min,val_max;
//
//		  //read struct (4 bytes) from esp
//		  if (fread(&hsv_struct,4,1,ser) != 1)
//			  printf("Error reading from UART");
//		  printf("\n%c,%c,%x,%x",hsv_struct[0],hsv_struct[1],hsv_struct[2],hsv_struct[3]);
//
//		  //check this is the right order
//		  colour=hsv_struct[0];
//		  type=hsv_struct[1];
//		  option=hsv_struct[2];
//		  value=hsv_struct[3];
//
//		  //parse struct
//		  if (type=='e'){
//			  col_sel=0;
//			  if (option){ // Increase exposure
//				  exposureTime += EXPOSURE_STEP;
//				  OV8865SetExposure(exposureTime);
//				  printf("\nExposure = %x ", exposureTime);
//			  } else { // Decrease exposure
//				  exposureTime -= EXPOSURE_STEP;
//				  OV8865SetExposure(exposureTime);
//				  printf("\nExposure = %x ", exposureTime);
//			  }
//		  } else if (type=='g'){
//			  col_sel=0;
//			  if (option){ // Increase gain
//				  gain += GAIN_STEP;
//				  OV8865SetGain(gain);
//				  printf("\nGain = %x ", gain);
//			  } else { // Decrease gain
//				  gain -= GAIN_STEP;
//				  OV8865SetGain(gain);
//				  printf("\nGain = %x ", gain);
//			  }
//		  } else if (type=='h'){
//			  col_sel = colour;
//			  if (option){ // Change maximum hue
//				  hsv_sel=1;
//				  hue_max = value;
//				  printf("\nMax Hue = %x ", value);
//			  } else { // Change minimum hue
//				  hsv_sel=2;
//				  hue_min = value;
//				  printf("\nMin Hue = %x ", value);
//			  }
//		  } else if (type=='s'){
//			  col_sel = colour;
//			  if (option){ // Change maximum saturation
//				  hsv_sel=3;
//				  sat_max = value;
//				  printf("\nMax Sat = %x ", value);
//			  } else { // Change minimum saturation
//				  hsv_sel=4;
//				  sat_min = value;
//				  printf("\nMin Sat = %x ", value);
//			  }
//		  } else if (type=='v'){
//			  col_sel = colour;
//			  if (option){ // Change maximum value
//				  hsv_sel=5;
//				  val_max = value;
//				  printf("\nMax Val = %x ", value);
//			  } else { // Change minimum value
//				  hsv_sel=6;
//				  val_min = value;
//				  printf("\nMin Val = %x ", value);
//			  }
//		  }

//			int in = getchar();
//		  switch (in) {
//			   case 'e': {
//				   exposureTime += EXPOSURE_STEP;
//				   OV8865SetExposure(exposureTime);
//				   printf("\nExposure = %x ", exposureTime);
//				   break;}
//			   case 'd': {
//				   exposureTime -= EXPOSURE_STEP;
//				   OV8865SetExposure(exposureTime);
//				   printf("\nExposure = %x ", exposureTime);
//				   break;}
//			   case 't': {
//				   gain += GAIN_STEP;
//				   OV8865SetGain(gain);
//				   printf("\nGain = %x ", gain);
//				   break;}
//			   case 'g': {
//				   gain -= GAIN_STEP;
//				   OV8865SetGain(gain);
//				   printf("\nGain = %x ", gain);
//				   break;}
//			   case 'r': {
//				   current_focus += manual_focus_step;
//				   if(current_focus >1023) current_focus = 1023;
//				   OV8865_FOCUS_Move_to(current_focus);
//				   printf("\nFocus = %x ",current_focus);
//				   break;}
//			   case 'f': {
//				   if(current_focus > manual_focus_step) current_focus -= manual_focus_step;
//				   OV8865_FOCUS_Move_to(current_focus);
//				   printf("\nFocus = %x ",current_focus);
//				   break;}
//		  }

		  // Update contrast of image
		  //IOWR(0x42000, EEE_IMGPROC_CONTRAST, 0xf);

		  //Update red threshold
//		  IOWR(0x42000, EEE_IMGPROC_RED_THRESH, 0x0);

		  // update colour to be detected when 3rd switch is on
//		  IOWR(0x42000, EEE_IMGPROC_COL_DETECT, 0x4000);

		  //update distance threshold between bounding boxes
//		  IOWR(0x42000, EEE_IMGPROC_DIST_THRESH, 0x20);

		  //select colour to change its hsv values with HUE, SAT, VAL
		  // 1: RED
		  // 2: PINK
		  // 3: YELLOW
		  // 4: GREEN
		  // 5: BLUE
//		  IOWR(0x42000, COL_SEL, col_sel+(hsv_sel<<4));

		  //Testing HSV values:
//		  IOWR(0x42000, HUE, hue_min+(hue_max<<8));
//		  IOWR(0x42000, SAT, sat_min+(sat_max<<8));
//		  IOWR(0x42000, VAL, val_min+(val_max<<8));
//		  IOWR(0x42000, HUE, 0x0e00);
//		  IOWR(0x42000, SAT, 0xae33);
//		  IOWR(0x42000, VAL, 0xff60);


	   //Main loop delay
		  usleep(10000);

   };
  return 0;
}
