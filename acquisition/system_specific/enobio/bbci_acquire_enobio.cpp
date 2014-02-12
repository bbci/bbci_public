/*
  bbci_acquire_en.c

  This file defines a mex-Function to communicate with the enobios
  server via matlab. The execution pathes are:
  1. state = bbci_acquire_en('init', state); 
  2. [data] = bbci_acquire_en(state);
  3. [data, marker_time] = bbci_acquire_en(state);
  4. [data, marker_time, marker_descr,state] = bbci_acquire_en(state);
*/

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <ctype.h>
#include <winsock2.h>
#include <winbase.h>
#include <queue>
#include <time.h>
#include "include\Enobio3G.h"
#include "include\channeldata.h"
#include "include\StatusData.h"
#include <string>
#include <sstream>
using namespace std;
using std::string;
#pragma comment(lib,"ws2_32.lib")
#pragma comment(lib,"enobio_api\\Enobio3GAPI.lib")

#include "mex.h"

/*
	GLOBAL VARIABLES
*/
static bool g_bIsConnected = false;  // shows where we are connected to the server or not
static bool g_bIsMac = false; // shows whether its a direct connection
static SOCKET g_Socket; // active socket, which is connected to the enobio server
static SOCKET g_ServerSocket; // active socket, which is connected to the enobio server
static SOCKET g_ActiveSocket; 
//static FILE *g_Fp;
// The Following Constants will only be used during the testing stages
// Afterwards the user will be able to set them(we will have to change the acquire function a little bit
const int p    = 5;          // Duration of the pause before acquisition (seconds, min 1s)
const int N    = 8;          // number of channels
const int bps  = 4;          // bytes per sample
const int Fs   = 500;        // Enobio's sampling rate
const int Ns   = 20;         // number of samples to read in the buffer each time (between 20 and 250)
const int buff = bps*Ns*N;   // Number of bytes to read in total for all channels
int  datenPuffer[Ns*N]={0};

// the status name constants
static const char* FIELD_IP = "hostIP";
static const char* FIELD_MAC = "hostMAC";
static const char* FIELD_Channels = "numChan";
static const char* FIELD_Freq = "freq";
struct chData
{
  int channels[20];
  unsigned long long timeStamp;
};
struct markerData
{
	string description;
	unsigned long long pos;
	unsigned long long timeStamp;
	double time;
};
static queue<chData> gDataQueue;
static queue<markerData> gMarkerQueue;

static HANDLE ghMutexData; 
static HANDLE ghMutexMarkers; 
static HANDLE ghMutexCount; 
static HANDLE  hServerThread;
static unsigned long long g_CurCount=0;
static unsigned int g_numCh=8;

//
// Definition of the consumers to receive both data and status from Enobio
//
class EnobioDataConsumer : public IDataConsumer
{
public:
    void receiveData (const PData& data);

	void setWindowHandler(HWND hWnd) {_hWnd = hWnd;}
private:
	HWND _hWnd;
};

class EnobioStatusConsumer : public IDataConsumer
{
public:
    void receiveData (const PData& data);
	
	void setWindowHandler(HWND hWnd) {_hWnd = hWnd;}
private:
	HWND _hWnd;
};

//
// Implementation of the receiveData for both Data and Status consumers
// The execution of these methods happens in a thread created by the Enobio
// instance so accesing GUI resources might lead to a program crash
//
void EnobioDataConsumer::receiveData(const PData &data)
{
  WaitForSingleObject(ghMutexData, INFINITE );
  WaitForSingleObject(ghMutexCount, INFINITE );
  
  chData newData;
  ChannelData * pData = (ChannelData *)data.getData();

  for(int i=0;i<g_numCh;i++)
    newData.channels[i] = pData->data()[i];
  newData.timeStamp = pData->timestamp();
  g_CurCount = newData.timeStamp;
  gDataQueue.push(newData);
  ReleaseMutex(ghMutexData);
  ReleaseMutex(ghMutexCount);
  
}
time_t getUnixTimeStamp()
{
	time_t seconds;
	FILETIME* ft = new FILETIME;
	SYSTEMTIME* st = new SYSTEMTIME;
	seconds = time (NULL);
	seconds*=1000;
	GetSystemTimeAsFileTime(ft);
	FileTimeToSystemTime(ft,st);
	seconds+=st->wMilliseconds;
	return seconds;
}
void EnobioStatusConsumer::receiveData(const PData &data)
{
  
}

//
// Declaration of Enobio and consumers
//

static Enobio3G enobio;
static EnobioDataConsumer* enobioDataConsumer = NULL;
static EnobioStatusConsumer* enobioStatusConsumer = NULL;

	static SOCKET markerPassiveSocket;
	static SOCKET markerActiveSocket;
DWORD WINAPI threadMarkerServer( LPVOID lpParam ) 
{ 
	char curMarker[256];
	FILETIME* ft = new FILETIME;
	SYSTEMTIME* st = new SYSTEMTIME;
	while(1) 	{			
		markerPassiveSocket = socket(AF_INET,		
									SOCK_DGRAM,   	
									0);		
		if(markerPassiveSocket==INVALID_SOCKET) {
			 mexErrMsgTxt("bbci_acquire_en: Init. Could not create Passive socket\n");
			return 1;
		}
		SOCKADDR_IN serverInfo;
		serverInfo.sin_family = AF_INET;
		serverInfo.sin_addr.s_addr = INADDR_ANY;	
		serverInfo.sin_port = htons(1206);		
		
		if(bind(markerPassiveSocket, (LPSOCKADDR)&serverInfo, sizeof(struct sockaddr))==SOCKET_ERROR) {
			mexErrMsgTxt("Could not bind socket. Make sure that the port is free");
			return 1;
		}
		struct sockaddr_in si_other;
		int slen=sizeof(si_other);
		int rBytes;
		while(1/*(rBytes=recv(markerActiveSocket,curMarker, 256,0))!=SOCKET_ERROR*/) {
        rBytes=recvfrom(markerPassiveSocket,curMarker, 256,0, (struct sockaddr *) &si_other, &slen);
			if(rBytes!=SOCKET_ERROR)
			{
			curMarker[4]=0;
			WaitForSingleObject(ghMutexMarkers, INFINITE );
			string curString = curMarker;
			mexPrintf("Received: %s\n",curMarker);
			markerData mData;
			mData.description = curString; 
			// mData.timeStamp = (unsigned long long) getUnixTimeStamp();
			//unsigned long long* recvTS = ((unsigned long long*) (&curMarker[248])); 
			//mexPrintf("%lld",*recvTS);
			mData.timeStamp = getUnixTimeStamp(); 
			bool isDone=false;
			unsigned long long lastTime = mData.timeStamp;
			
			unsigned long long startTime = getUnixTimeStamp();
			while(!isDone)
			{
				WaitForSingleObject(ghMutexCount, INFINITE );
					
				if(lastTime<=(g_CurCount))
				{
					isDone=true;
					mData.timeStamp=g_CurCount;
					//mexPrintf("\nlastTime:%lld CurCount:%lld\n",lastTime,g_CurCount);
				}
				ReleaseMutex( ghMutexCount);
			}
			unsigned long long endTime = getUnixTimeStamp();
			unsigned long long timeNeeded = endTime - startTime;
			
			gMarkerQueue.push(mData);
			ReleaseMutex(ghMutexMarkers);
			}
		}
		closesocket(markerActiveSocket);
		
	}
	return 0;
}


SOCKET initConnection()
{
  SOCKET s;
  SOCKADDR_IN address;
  WSADATA wsa;
  short  datenPuffer[bps*Ns/2]={0};
  if(WSAStartup(MAKEWORD(2,0),&wsa)) {
    mexErrMsgTxt("bbci_acquire_en: Init. Error during WSA Startup\n");
	return INVALID_SOCKET;
  }
  memset(&address,0,sizeof(SOCKADDR_IN));

  if((s=socket(AF_INET,SOCK_STREAM,0))==INVALID_SOCKET)
  {
    mexErrMsgTxt("bbci_acquire_en: Init. Error during socket initialization\n");
	return INVALID_SOCKET;
  }

  address.sin_family=AF_INET;
  address.sin_port=htons(1234); 
  address.sin_addr.s_addr=inet_addr("127.0.0.1"); 

  if(connect(s,(SOCKADDR*)&address,sizeof(SOCKADDR))==SOCKET_ERROR)
  {
     mexErrMsgTxt("bbci_acquire_en: Init. Error during connection to server.\n");
  }
  
  return s;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	mxChar *pi;
		
	 unsigned char mac[6] = {0xcd, 0x02, 0x4c, 0x80, 0x07, 0x00};
	// Function case 1. 
	if(nrhs==2&&mxIsChar(prhs[0]) && mxIsStruct(prhs[1]))	{
		int len = mxGetM(prhs[0]) * mxGetN(prhs[0])+1;
		char* cPi = (char*) mxCalloc(len,sizeof(char));
		
		mxGetString(prhs[0],cPi,len);
		

		if(nlhs!=1)
		{
			mexErrMsgTxt("bbci_acquire_en: invalid number of outputs. init has only one output variable");
		}
		else if(!strcmp(cPi,"init")) {

			if(g_bIsConnected) {
				mexErrMsgTxt("bbci_acquire_en: already connected. please close the other connection");
			}
			else {
				mxArray* hostMac = mxGetField(prhs[1], 0,FIELD_MAC);
				mxArray* numChannels = mxGetField(prhs[1], 0,FIELD_Channels);
				if(numChannels)
				{
					double* t= (double*)mxGetData(numChannels);
					g_numCh = *t;
				}
				if(hostMac) {
				    int maclen = (mxGetM(hostMac) * mxGetN(hostMac)) + 1;
					char* macbuff = new char[18];
				
					if(maclen!=18)
					{
						mexErrMsgTxt("Invalid Mac Address");
						return;
					}
					mxGetString(hostMac, macbuff, 18);
					// mexPrintf("%s",macbuff);
					gMarkerQueue = queue<markerData>();
					gDataQueue = queue<chData>();					
					for(int i=0;i<6;i++)
					{
						char macpart[3]={0};
						int macbyte;
						int startidx = i*3;
						std::stringstream ss;
						
						macpart[0] = macbuff[startidx];
						macpart[1] = macbuff[startidx+1];
						ss << hex << macpart;
						ss >> macbyte;
						// mexPrintf("\n %s %x \n",macpart ,macbyte);
						mac[5-i] =macbyte; 
						
					}

					g_bIsMac = true;
					ghMutexData = CreateMutex( 
											NULL,              // default security attributes
											FALSE,             // initially not owned
											NULL);             // unnamed mutex
					if(!enobioDataConsumer)
					{
						enobioDataConsumer = new EnobioDataConsumer();
						enobio.registerConsumer(Enobio3G::ENOBIO_DATA, *enobioDataConsumer);
					}
					if(!enobioStatusConsumer)
					{
						enobioStatusConsumer = new EnobioStatusConsumer();
						enobio.registerConsumer(Enobio3G::STATUS, *enobioStatusConsumer);
					}
					mxArray* OUT_STATE;
					OUT_STATE = mxDuplicateArray(prhs[1]);
					
					plhs[0] = OUT_STATE;

					
					
					  if (!enobio.openDevice(mac)) {
					  mexErrMsgTxt("Error opening device.Make sure that there is no existing connection or that the device is plugged in");
					}
					 else {
						g_bIsConnected = true;
						//g_Fp=fopen("D:\\testDelay.txt", "w");
						enobio.startStreaming();
					}
					DWORD dummy;
					  hServerThread = CreateThread( 
						NULL,                   // default security attributes
						0,                      // use default stack size  
						threadMarkerServer,       // thread function name
						NULL,          // argument to thread function 
						0,                      // use default creation flags 
						&dummy);   // returns the thread identifier 
						SetThreadPriority(hServerThread,THREAD_PRIORITY_HIGHEST);
				}
				else if((!strcmp(cPi,"quit"))||(!strcmp(cPi,"close"))) {
					g_bIsConnected = false;
					g_numCh = 8;
					//fclose(g_Fp);
					gDataQueue = queue<chData>();
					gMarkerQueue = queue<markerData>();
					enobio.stopStreaming();
					enobio.closeDevice();
					TerminateThread(hServerThread,0);
					CloseHandle(hServerThread);
					closesocket(markerPassiveSocket);
				}
				else {
					if((g_Socket=initConnection()) != INVALID_SOCKET)
					{
						g_bIsConnected = true;
						mxArray* OUT_STATE;
						OUT_STATE = mxDuplicateArray(prhs[1]);

						plhs[0] = OUT_STATE;
						return;
					}
				}
			}
		}
		else {
			mexErrMsgTxt("bbci_acquire_en: invalid string in first parameter. Did you mean init?");
		}
	}
	
	// Function case 2
	else if(nrhs==1&&nlhs==1 && mxIsStruct(prhs[0])) {
		if(g_bIsMac) {
			WaitForSingleObject(ghMutexData, INFINITE );
			WaitForSingleObject(ghMutexMarkers, INFINITE );
			int count = gDataQueue.size();
			int count2 = gMarkerQueue.size();
			double* output = new double[count*g_numCh];
			//mexPrintf("COUNT: %d",count);
			for(int i=0;i<count;i++) {
				chData newData = gDataQueue.front();
				for(int j=0;j<g_numCh;j++)
				{
					output[i*g_numCh+j] = newData.channels[j];
				}
				gDataQueue.pop();
			}
			
			g_CurCount=0;
			gMarkerQueue = queue<markerData>();
			
			ReleaseMutex( ghMutexData);
			ReleaseMutex( ghMutexMarkers);
			plhs[0] = mxCreateDoubleMatrix(g_numCh,count,mxREAL);
			double  *start_of_output;
			start_of_output = (double *)mxGetPr(plhs[0]);
			memcpy(start_of_output, output, g_numCh*sizeof(double)*count);
			
			delete[] output;
			
		}
		else {
			recv(g_Socket, (char*) datenPuffer, N*bps*Ns,0);
			double* output = new double[N*Ns];
			for(int i=0;i<N*Ns;i++)
				output[i] = datenPuffer[i];
				
			
			plhs[0] = mxCreateDoubleMatrix(N,Ns,mxREAL);
			// mxSetData(plhs[0],output);
			double  *start_of_output;
			start_of_output = (double *)mxGetPr(plhs[0]);
			memcpy(start_of_output, output, N * Ns * sizeof(double) );
		}
	}
	// function case 3 and 4
		else if(nrhs==1&&nlhs>1 && mxIsStruct(prhs[0])) {
		if(g_bIsMac) {
			bool isDone = false;
			WaitForSingleObject(ghMutexData, INFINITE );
			int preCount=gDataQueue.size();
			ReleaseMutex( ghMutexData);
			
			if(preCount>0)
			{
				WaitForSingleObject(ghMutexMarkers, INFINITE );
				WaitForSingleObject(ghMutexData, INFINITE );
				int count_markers = gMarkerQueue.size();
				double* output2 = new double[count_markers];
				char** output3 = new char*[count_markers];
				double* output4 = new double[count_markers];
				
				for(int i=0;i<count_markers;i++)
					output3[i] = new char[256];
				markerData* allMarkers =  new markerData[count_markers]; 
				for(int i=0;i<count_markers;i++)
				{
					allMarkers[i] = gMarkerQueue.front();
					strcpy(output3[i],gMarkerQueue.front().description.c_str());
					gMarkerQueue.pop();
					//mexPrintf("%s\n",output3[i]);
				}

				int count = gDataQueue.size();
				
				double* output = new double[count*g_numCh];

				
				unsigned long long* dataTime = new unsigned long long[count];
				

				
				for(int i=0;i<count;i++) {
					chData newData = gDataQueue.front();
					
					for(int j=0;j<g_numCh;j++)
					{
					//	if(!newData.channels[j])
					//		mexPrintf("\nZERO CH: %d", j);
						output[j*count+i] = (newData.channels[j]/1000.0l); 
					}
					dataTime[i] = (unsigned long long)newData.timeStamp;
					gDataQueue.pop();
				}
				
				
				
				unsigned long long startTime = dataTime[0];
				for(int i=0;i<count_markers;i++)
				{
					// mexPrintf("\nStart time:%lld\n",startTime);
					unsigned long long diff = allMarkers[i].timeStamp - startTime;
					
					//fprintf(g_Fp, "%lld\n",diff);
					if(startTime>allMarkers[i].timeStamp)
					{	
					diff = 0;
					}

					output2[i] = diff;
				}
				
				plhs[0] = mxCreateDoubleMatrix(count,g_numCh,mxREAL);
				double  *start_of_output;
				start_of_output = (double *)mxGetPr(plhs[0]);
				memcpy(start_of_output, output, g_numCh*sizeof(double)*count);
				
				plhs[1] = mxCreateDoubleMatrix(1,count_markers,mxREAL);
				
				start_of_output = (double *)mxGetPr(plhs[1]);
				memcpy(start_of_output, output2, sizeof(double)*count_markers);
						
				int dims[2];
				dims[0] = 1;
				dims[1] = count_markers;
				
				//plhs[2] = mxCreateCellArray (2,dims);
				plhs[2] = mxCreateDoubleMatrix(1,count_markers,mxREAL);
				
				plhs[3] = mxDuplicateArray(prhs[0]);
				
				for(int i=0;i<count_markers;i++)
				{
					string s(&output3[i][1]);
					istringstream(s) >> output4[i];
				}
				start_of_output = (double *)mxGetPr(plhs[2]);
				memcpy(start_of_output, output4, sizeof(double)*count_markers);

				/*
				for(int i=0;i<count_markers;i++)
				{
				int arr[2];
				arr[0] = 0;
				arr[1] = i;
				int index = mxCalcSingleSubscript(plhs[2] , 2, arr);
				mxArray* curString =  mxCreateString(output3[i]);
				mxSetCell(plhs[2], index, curString);
				}
				*/
				
				delete[] allMarkers;
				delete[] output;
				delete[] output2;
				delete[] output4;
				delete[] dataTime;
				for(int i=0;i<count_markers;i++)
					delete[] output3[i];
				delete[] output3;
				ReleaseMutex( ghMutexMarkers);
				ReleaseMutex( ghMutexData);
				Sleep(3);
			}
			else
			{
				plhs[0] = mxCreateDoubleMatrix(g_numCh,0,mxREAL);
				plhs[1] = mxCreateDoubleMatrix(g_numCh,0,mxREAL);
				int dims[2];
				dims[0] = 1;
				dims[1] = 0;
				
				plhs[2] = mxCreateCellArray (2,dims);
				
				
				plhs[3] = mxDuplicateArray(prhs[0]);
			}
		}
		else {
			recv(g_Socket, (char*) datenPuffer, N*bps*Ns,0);
			double* output = new double[N*Ns];
			for(int i=0;i<N*Ns;i++)
				output[i] = datenPuffer[i];
				
			
			plhs[0] = mxCreateDoubleMatrix(N,Ns,mxREAL);
			// mxSetData(plhs[0],output);
			double  *start_of_output;
			start_of_output = (double *)mxGetPr(plhs[0]);
			memcpy(start_of_output, output, N * Ns * sizeof(double) );
		}
	}
	// Close
	else if(nlhs==0&&nrhs==1)
	{
		g_bIsConnected = false;
		g_numCh = 8;
		//fclose(g_Fp);
		gDataQueue = queue<chData>();
		gMarkerQueue = queue<markerData>();
		enobio.stopStreaming();
		enobio.closeDevice();
		TerminateThread(hServerThread,0);
		CloseHandle(hServerThread);
		closesocket(markerPassiveSocket);
	}
}