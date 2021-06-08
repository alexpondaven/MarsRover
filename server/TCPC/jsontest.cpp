#include <iostream>
#include <string>
#include "ArduinoJson.h"
#include <sys/socket.h>
#include <arpa/inet.h>
#define PORT 2000


int main() {
    int sock = 0, valread;
    struct sockaddr_in serv_addr;
    char hello[] = "Hello from client";
    char buffer[1024] = {0};
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        printf("\n Socket creation error \n");
        return -1;
    }
   
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);
       
    // Convert IPv4 and IPv6 addresses from text to binary form
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0) 
    {
        printf("\nInvalid address/ Address not supported \n");
        return -1;
    }
   
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
        printf("\nConnection Failed \n");
        return -1;
    }
    
    

    int x_coord=0, y_coord=0, speed=10, direction=0;
    int cols[5]={1,2,3,4,5};
    float angles[5]={1.0f,2.0f,3.0f,4.0f,5.0f}, dists[5]={6.0f,7.0f,8.0f,9.0f,0.0f};

  while (1)
  { 
    char c;
    std::cout << "Press any key to send, 'q' to exit" << std::endl;
    std::cin >> c;
    if (c=='q') {
      break;
    }
    StaticJsonDocument<1024> doc;
    
    
    JsonObject coords = doc.createNestedObject("position");

    JsonArray cls = doc.createNestedArray("colors");
    JsonArray ags = doc.createNestedArray("angle");
    JsonArray dts = doc.createNestedArray("distance");
    coords["X"] = x_coord;
    coords["Y"] = y_coord;
    coords["speed"] = speed;
    coords["direction"] = direction;
    for (int i=0; i<5; i++) {
      cls[i] = cols[i];
      ags[i] = angles[i];
      dts[i] = dists[i];
    }
    std::string s="", t="";

    serializeJsonPretty(doc,s);
    serializeJson(doc, t);
    std::cout << s << std::endl;
    uint32_t msg_len = strlen(t.c_str());

    /**
     * Comment out the next line to not send the size of string in the first 4 bytes
     */
    // send(sock, &msg_len, 4, 0);

    
    send(sock , t.c_str() , strlen(t.c_str()) , 0 );
    printf("message sent\n");


  }
  

    return 0;
}