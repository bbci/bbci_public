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
#include <windows.h>
#include <wchar.h>
#include <conio.h>
#include <tchar.h> 
#include <assert.h>
#include <queue>
#include <time.h>
#include <string>
#include <sstream>
using namespace std;
using std::string;
#pragma comment(lib,"ws2_32.lib")


#include "mex.h"
#include "TmsiSDK.h" 

#define NUM_CHAN 34
#define FREQ 1000
/*
	GLOBAL VARIABLES
*/
static bool g_bIsConnected = false;  // shows where we are connected to the server or not
static bool g_bIsMac = false; // shows whether its a direct connection
static SOCKET g_Socket; // active socket, which is connected to the enobio server
static SOCKET g_ServerSocket; // active socket, which is connected to the enobio server
static SOCKET g_ActiveSocket; 
//static FILE *g_Fp;

static int g_NumberOfChannels;
unsigned int g_BytesPerSample;
static ULONG g_SampleRateInMilliHz;
static ULONG g_SignalBufferSizeInSamples;
static ULONG g_SampleRateInHz;
static HANDLE g_Handle;
static HINSTANCE g_LibHandle;
static unsigned long long g_total;
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
static const char* FIELD_Freq = "fs";
static const char* FIELD_Ref = "commonAverageRef";
static const char* FIELD_Policy = "subsamplePolicy";


struct chData
{
  int channels[34];
  unsigned long long timeStamp;
};
struct markerData
{
	string description;
	unsigned long long pos;
	unsigned long long timeStamp;
	double time;
};

void quitTMSI();
static queue<chData> gDataQueue;
static queue<markerData> gMarkerQueue;

static HANDLE ghMutexData; 
static HANDLE ghMutexMarkers; 
static HANDLE ghMutexCount; 
static HANDLE  hServerThread;
static HANDLE  hObtainThread;
static unsigned long long g_CurCount=0;
static unsigned int g_numCh=8;
static unsigned int g_Ref=1;
static unsigned int g_PolicyMean=1;

static double g_Fs=FREQ;
static bool bTerminate=false;

static POPEN fpOpen;
static PCLOSE fpClose; 
static PSTART fpStart;
static PSTOP fpStop;	
static PSETSIGNALBUFFER fpSetSignalBuffer;
static PGETSAMPLES	fpGetSamples;
static PGETSIGNALFORMAT fpGetSignalFormat; 
static PFREE fpFree;
static PLIBRARYINIT fpLibraryInit;
static PLIBRARYEXIT fpLibraryExit;
static PGETFRONTENDINFO fpGetFrontEndInfo;
static PSETRTCTIME fpSetRtcTime;
static PGETRTCTIME fpGetRtcTime;
static PSETRTCALARMTIME fpSetRtcAlarmTime;
static PGETRTCALARMTIME fpGetRtcAlarmTime;
static PGETERRORCODE fpGetErrorCode;
static PGETERRORCODEMESSAGE fpGetErrorCodeMessage;
static PFREEDEVICELIST fpFreeDeviceList;
static PGETDEVICELIST fpGetDeviceList;
static PGETCONNECTIONPROPERTIES fpGetConnectionProperties;
static PSETMEASURINGMODE fpSetMeasuringMode;
static PSETREFCALCULATION fpSetRefCalculation;
static PGETBUFFERINFO fpGetBufferInfo;

// Functions for Mobita
static PSTARTCARDFILE fpStartCardFile;
static PSTOPCARDFILE fpStopCardFile;
static PGETCARDFILESAMPLES fpGetCardFileSamples;
static PGETCARDFILESIGNALFORMAT fpGetCardFileSignalFormat;
static POPENCARDFILE fpOpenCardFile;
static PGETCARDFILELIST fpGetCardFileList;
static PCLOSECARDFILE fpCloseCardFile;
static PGETRECORDINGCONFIGURATION fpGetRecordingConfiguration;
static PSETRECORDINGCONFIGURATION fpSetRecordingConfiguration;
static PGETEXTFRONTENDINFO fpGetExtFrontEndInfo;

//Functions for Nexus10-MKII
static PGETRANDOMKEY fpGetRandomKey;
static PUNLOCKFRONTEND fpUnlockFrontEnd;
static PGETOEMSIZE fpGetOEMSize;
static PSETOEMDATA fpSetOEMData;
static PGETOEMDATA fpGetOEMData;
static PSETSTORAGEMODE fpSetStorageMode;

static POPENFIRSTDEVICE fpOpenFirstDevice;


static PSIGNAL_FORMAT psf = NULL;
static FRONTENDINFO FrontEndInfo;

static time_t g_startTime;

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

DWORD WINAPI threadObtain( LPVOID lpParam ) 
{

	unsigned int* SignalBuffer, SignalBufferSizeInBytes;
	float Fval[NUM_CHAN];
	SignalBufferSizeInBytes = g_SignalBufferSizeInSamples*NUM_CHAN*sizeof(SignalBuffer[0]);
	SignalBuffer = (unsigned int*) malloc(SignalBufferSizeInBytes);

			while(1) {
//			mexPrintf("bla");
			int BytesReturned = fpGetSamples(g_Handle,(PULONG) SignalBuffer, SignalBufferSizeInBytes);
			int NrSamples = BytesReturned/(g_NumberOfChannels*sizeof(unsigned int));
			for(int i=0;i<NrSamples;i++) {
				for(int j=0;j<g_NumberOfChannels;j++) {
					int ind = i*g_NumberOfChannels+j;
					if(SignalBuffer[ind] == OVERFLOW_32BITS && 
							(psf[j].Type == CHANNELTYPE_EXG || 
							psf[j].Type == CHANNELTYPE_BIP || 
							psf[j].Type == CHANNELTYPE_AUX ))
								Fval[j] = 0;
					else {
						switch(psf[j].Format) {
							case SF_UNSIGNED:
								Fval[j] = SignalBuffer[ind] *  psf[j].UnitGain +  psf[j].UnitOffSet ;
								break ;
							case SF_INTEGER: // signed integer
								Fval[j] = ((int) SignalBuffer[ind]) *  psf[j].UnitGain +  psf[j].UnitOffSet ;
								break ;
							default : 
								Fval[j] = 0 ; // For unknown types, set the value to zero 
								break ;
						}
					}
				}
				
				
				if(bTerminate)
				{
					bTerminate=false;
					return 0;
				}
				WaitForSingleObject(ghMutexData, INFINITE );
				WaitForSingleObject(ghMutexCount, INFINITE );
				
				chData newData;
				  for(int i=0;i<g_numCh;i++)
						newData.channels[i] = Fval[i];
				  newData.timeStamp = g_CurCount=getUnixTimeStamp();

					  gDataQueue.push(newData);
	
				
				ReleaseMutex(ghMutexData);
				ReleaseMutex(ghMutexCount);
			
				if(bTerminate)
				{
					bTerminate=false;
					return 0;
				}
			}
		}
	
	return 0;
}

char **DeviceList = NULL;
int NrOfDevices=0;

void errorExit() {
			if(g_Handle) {
				fpLibraryExit( g_Handle );
				Sleep(1000);
			}
			if(g_LibHandle) {
				FreeLibrary(g_LibHandle);
				g_LibHandle = NULL;
			}
}

// initialize tmsi
int initTMSI() {
	TCHAR LibraryName[255] = _T("\\TmsiSDK.dll");
	TCHAR Path[	MAX_PATH ];
	int ErrorCode=0;
	GetSystemDirectory(Path, sizeof(Path) / sizeof(TCHAR) );
	lstrcat(Path, LibraryName);
	g_LibHandle = LoadLibrary(Path);
	

	if(!g_LibHandle) {
		mexPrintf("ERROR. Cannot load DLL. Are the tmsi drivers installed?");
		return 1;
	}
	
	fpOpen				= (POPEN)			GetProcAddress(g_LibHandle,"Open");
	fpClose				= (PCLOSE)			GetProcAddress(g_LibHandle,"Close");
	fpStart				= (PSTART)			GetProcAddress(g_LibHandle,"Start");
	fpStop				= (PSTOP)			GetProcAddress(g_LibHandle,"Stop");
	fpSetSignalBuffer	= (PSETSIGNALBUFFER)GetProcAddress(g_LibHandle,"SetSignalBuffer");
	fpGetSamples		= (PGETSAMPLES)		GetProcAddress(g_LibHandle,"GetSamples");
	fpGetBufferInfo		= (PGETBUFFERINFO)	GetProcAddress(g_LibHandle,"GetBufferInfo");
	fpGetSignalFormat	= (PGETSIGNALFORMAT)GetProcAddress(g_LibHandle,"GetSignalFormat"); 
	fpFree				= (PFREE)			GetProcAddress(g_LibHandle, "Free" ); 
	fpLibraryInit		= (PLIBRARYINIT)	GetProcAddress(g_LibHandle, "LibraryInit" ); 
	fpLibraryExit		= (PLIBRARYEXIT)	GetProcAddress(g_LibHandle, "LibraryExit" ); 
	fpGetFrontEndInfo	= (PGETFRONTENDINFO) GetProcAddress(g_LibHandle, "GetFrontEndInfo" ); 
	fpSetRtcTime		= (PSETRTCTIME)		GetProcAddress(g_LibHandle, "SetRtcTime" ); 
	fpGetRtcTime		= (PGETRTCTIME)		GetProcAddress(g_LibHandle, "GetRtcTime" ); 
	fpSetRtcAlarmTime	= (PSETRTCALARMTIME)GetProcAddress(g_LibHandle, "SetRtcAlarmTime" ); 
	fpGetRtcAlarmTime	= (PGETRTCALARMTIME)GetProcAddress(g_LibHandle, "GetRtcAlarmTime" ); 
	fpGetErrorCode		= (PGETERRORCODE)	GetProcAddress(g_LibHandle, "GetErrorCode" ); 
	fpGetErrorCodeMessage = (PGETERRORCODEMESSAGE) GetProcAddress(g_LibHandle, "GetErrorCodeMessage" ); 
	fpGetDeviceList		= (PGETDEVICELIST)	GetProcAddress(g_LibHandle, "GetDeviceList" ); 
	fpFreeDeviceList	= (PFREEDEVICELIST)	GetProcAddress(g_LibHandle, "FreeDeviceList" ); 
	fpStartCardFile		= (PSTARTCARDFILE)	GetProcAddress(g_LibHandle, "StartCardFile" ); 
	fpStopCardFile		= (PSTOPCARDFILE)	GetProcAddress(g_LibHandle, "StopCardFile" ); 
	fpGetCardFileSamples	= (PGETCARDFILESAMPLES)	GetProcAddress(g_LibHandle, "GetCardFileSamples" ); 
	fpGetConnectionProperties = (PGETCONNECTIONPROPERTIES)	GetProcAddress(g_LibHandle, "GetConnectionProperties" ); 
	fpGetCardFileSignalFormat = (PGETCARDFILESIGNALFORMAT) GetProcAddress(g_LibHandle, "GetCardFileSignalFormat" ); 
	fpOpenCardFile		= (POPENCARDFILE) GetProcAddress(g_LibHandle, "OpenCardFile" ); 
	fpGetCardFileList	= (PGETCARDFILELIST) GetProcAddress(g_LibHandle, "GetCardFileList" ); 
	fpCloseCardFile		= (PCLOSECARDFILE) GetProcAddress(g_LibHandle, "CloseCardFile" );
	fpGetExtFrontEndInfo = (PGETEXTFRONTENDINFO) GetProcAddress(g_LibHandle, "GetExtFrontEndInfo");
	fpSetMeasuringMode	= (PSETMEASURINGMODE) GetProcAddress(g_LibHandle, "SetMeasuringMode" );
	fpGetRecordingConfiguration = (PGETRECORDINGCONFIGURATION) GetProcAddress(g_LibHandle, "GetRecordingConfiguration" );
	fpSetRecordingConfiguration = (PSETRECORDINGCONFIGURATION) GetProcAddress(g_LibHandle, "SetRecordingConfiguration" );
	fpSetRefCalculation = (PSETREFCALCULATION) GetProcAddress(g_LibHandle, "SetRefCalculation" );
	fpGetRandomKey = (PGETRANDOMKEY) GetProcAddress(g_LibHandle, "GetRandomKey");
	fpUnlockFrontEnd=(PUNLOCKFRONTEND) GetProcAddress(g_LibHandle, "UnlockFrontEnd");
	fpGetOEMSize=(PGETOEMSIZE) GetProcAddress(g_LibHandle, "GetOEMSize");
	fpGetOEMData=(PGETOEMDATA) GetProcAddress(g_LibHandle, "GetOEMData");
	fpSetOEMData=(PSETOEMDATA) GetProcAddress(g_LibHandle, "SetOEMData");
	fpOpenFirstDevice = (POPENFIRSTDEVICE) GetProcAddress(g_LibHandle, "OpenFirstDevice" );
	fpSetStorageMode = (PSETSTORAGEMODE) GetProcAddress(g_LibHandle, "SetStorageMode");

	if(!fpGetRecordingConfiguration) {
		mexPrintf("Failed to load functions from dll");
		return 1;
	}
	
	g_Handle = fpLibraryInit( TMSiConnectionUSB, &ErrorCode );
	
	if(ErrorCode) {
		mexPrintf("Failed to initialize the library with Library Init. Errorcode = %d", ErrorCode); 
		return 1; 
	}

	DeviceList = fpGetDeviceList( g_Handle, &NrOfDevices);
	
	if(!NrOfDevices) {
		errorExit();
		mexErrMsgTxt("0 devices found. Have you connected any devices?");
		return 1;
	}

	char FrontEndName[MAX_FRONTENDNAME_LENGTH];
		
	psf = NULL;
	FRONTENDINFO FrontEndInfo;
	int Status;
	char *DeviceLocator = DeviceList[0];
	Status = fpOpen(g_Handle,DeviceLocator);
	
	if(!Status) {
			
		errorExit();
		mexErrMsgTxt("Could not Open");
		return 1;
	}
	Status = fpGetFrontEndInfo(g_Handle,&FrontEndInfo);
	psf = fpGetSignalFormat(g_Handle,FrontEndName);
//		for(int i=0;i<34;i++)
//			mexPrintf("Offset ch %d, %f, %f",i,psf[i].UnitGain,psf[i].UnitOffSet);
			
		
	if(!psf) {
		
		errorExit();
		ErrorCode = fpGetErrorCode(g_Handle);
		mexErrMsgTxt("Error getting Signal Format");
		return 1;
	}
		
	g_NumberOfChannels = psf->Elements;
	g_BytesPerSample = g_NumberOfChannels * sizeof(long);
		
	g_SampleRateInMilliHz = FREQ * 1000;
	g_SignalBufferSizeInSamples = g_SampleRateInMilliHz/1000;
	g_SampleRateInHz = g_SampleRateInMilliHz/1000;
		
	if(fpSetSignalBuffer(g_Handle, &g_SampleRateInMilliHz,&g_SignalBufferSizeInSamples) != TRUE) 
	{
		errorExit();
		mexErrMsgTxt("Error Setting Signal Buffer");
		return 1;
	}
	
	unsigned int SignalStrength, NrOfCRCErrors, NrOfSampleBlocks;
		
	Status = fpGetConnectionProperties(g_Handle, &SignalStrength,&NrOfCRCErrors, &NrOfSampleBlocks);
	if(!Status) {
		errorExit();
		mexErrMsgTxt("Error acquiring Connection Properties");
		return 1;
	}
		
	g_startTime =  getUnixTimeStamp(); 
	g_CurCount = g_startTime;
	
	if(g_Ref) {
		int res = fpSetRefCalculation(g_Handle,1);
		mexPrintf("Acitvating Reference Calculation\n");
	}
	else {
		fpSetRefCalculation(g_Handle,0);
		mexPrintf("Reference Calculation Turned Off\n");
	}
	
	if(!fpStart(g_Handle))
		{
			errorExit();
			mexErrMsgTxt("Error starting recording");
			return 1;
		}
		DWORD dummy;
					  hObtainThread = CreateThread( 
						NULL,                   // default security attributes
						0,                      // use default stack size  
						threadObtain,       // thread function name
						NULL,          // argument to thread function 
						0,                      // use default creation flags 
						&dummy);   // returns the thread identifier 
		g_bIsConnected = true;

		return 0;
}

//
// Declaration of Enobio and consumers
//



	static SOCKET markerPassiveSocket;
	static SOCKET markerActiveSocket;
DWORD WINAPI threadMarkerServer( LPVOID lpParam ) 
{ 
	char curMarker[256];
	FILETIME* ft = new FILETIME;
	SYSTEMTIME* st = new SYSTEMTIME;
//	while(1) 	{			
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
			
			if(!strncmp(curMarker,"QUIT_CALLED",rBytes)) {
				mexPrintf("QUITTING");
				break;
			}
			curMarker[4]=0;
			WaitForSingleObject(ghMutexMarkers, INFINITE );
			string curString = curMarker;
			mexPrintf("Received: %s\n",curMarker);
			markerData mData;
			mData.description = curString; 
			// mData.timeStamp = (unsigned long long) getUnixTimeStamp();
			//unsigned long long* recvTS = ((unsigned long long*) (&curMarker[248])); 
			//mexPrintf("%lld",*recvTS);
			 
			bool isDone=false;
			

			unsigned long long startTime = getUnixTimeStamp();
			mData.timeStamp = getUnixTimeStamp();
			unsigned long long lastTime = mData.timeStamp;
//			while(!isDone)
//			{
				WaitForSingleObject(ghMutexCount, INFINITE );
					
				if(g_CurCount<=lastTime)
				{
				//	isDone=true;
					mData.timeStamp=g_CurCount;
					//mexPrintf("\nlastTime:%lld CurCount:%lld\n",lastTime,g_CurCount);
				}
				ReleaseMutex( ghMutexCount);
//			}
			unsigned long long endTime = getUnixTimeStamp();
			unsigned long long timeNeeded = endTime - startTime;
			
			gMarkerQueue.push(mData);
			ReleaseMutex(ghMutexMarkers);
			}
		}
		//closesocket(markerActiveSocket);
		closesocket(markerPassiveSocket);
//	}
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
		else if(!strcmp(cPi,"init")) 
		{
			if(g_bIsConnected) {
				mexPrintf("ALREADY CONNECTED. CLOSING PREVIOUS CONNECTION");
				quitTMSI();
			}
			mexPrintf("STARTING\n");
			g_PolicyMean=1;
				gMarkerQueue = queue<markerData>();
				gDataQueue = queue<chData>();	
				g_numCh=8;
				mxArray* numChannels = mxGetField(prhs[1], 0,FIELD_Channels);
				if(numChannels)
				{
					double* t= (double*)mxGetData(numChannels);
					g_numCh = *t;
				}
				mxArray* ref = mxGetField(prhs[1], 0,FIELD_Ref);
				g_Ref=1;
				
				if(ref)
				{
					double* t= (double*)mxGetData(ref);
					g_Ref = *t;
				}
				g_Fs=FREQ;
				mxArray* fs = mxGetField(prhs[1], 0,FIELD_Freq);
				if(fs) 
				{
					double* t= (double*)mxGetData(fs);
					g_Fs = *t;	
				}
				
				mxArray* policy = mxGetField(prhs[1], 0,FIELD_Policy);
				
				g_PolicyMean = 1;
				
				if(policy) 
				{
					int pollen = (mxGetM(policy) * mxGetN(policy)) + 1;
					char* polbuff = new char[pollen+1];
					mxGetString(policy, polbuff, pollen);
					
					if(!strcmpi("subsamplebylag",polbuff)) 
					{
						mexPrintf("SUBSAMPLING BY LAG\n");
						g_PolicyMean = 0;
					}
					else 
					{
						mexPrintf("SUBSAMPLING BY MEAN\n");
					}
				}
				else 
				{
						mexPrintf("SUBSAMPLING BY MEAN\n");
				}
				

				ghMutexData = CreateMutex(NULL,              // default security attributes
										  FALSE,             // initially not owned
										  NULL);             // unnamed mutex
				ghMutexMarkers = CreateMutex(NULL,              // default security attributes
										  FALSE,             // initially not owned
										  NULL);             // unnamed mutex
				ghMutexCount= CreateMutex(NULL,              // default security attributes
										  FALSE,             // initially not owned
										  NULL);             // unnamed mutex
		 
				mxArray* OUT_STATE;
				OUT_STATE = mxDuplicateArray(prhs[1]);
				plhs[0] = OUT_STATE;
				
				if(!initTMSI())
				{
					DWORD dummy;
					hServerThread = CreateThread( 
									NULL,                   // default security attributes
									0,                      // use default stack size  
									threadMarkerServer,       // thread function name
									NULL,          // argument to thread function 
									0,                      // use default creation flags 
									&dummy);   // returns the thread identifier 
								
				}
				
			
		}
		else if((!strcmp(cPi,"quit"))||(!strcmp(cPi,"close"))) {	
			quitTMSI();
		}
		else {
			mexErrMsgTxt("bbci_acquire_tmsi: invalid string in first parameter. Did you mean init?");
		}
	}
	
	// Function case 2
	else if(nrhs==1&&nlhs==1 && mxIsStruct(prhs[0])) {
			WaitForSingleObject(ghMutexData, INFINITE );
			WaitForSingleObject(ghMutexMarkers, INFINITE );
			int count = gDataQueue.size();
			int count2 = gMarkerQueue.size();
			double* output = new double[count*g_numCh];
			//mexmexPrintf("COUNT: %d",count);
			for(int i=0;i<count;i++) {
				chData newData = gDataQueue.front();
				for(int j=0;j<g_numCh;j++)
				{
					output[i*g_numCh+j] = newData.channels[j];
				}
				gDataQueue.pop();
			}
			
			//g_CurCount=0;
			gMarkerQueue = queue<markerData>();
			
			ReleaseMutex( ghMutexData);
			ReleaseMutex( ghMutexMarkers);
			plhs[0] = mxCreateDoubleMatrix(g_numCh,count,mxREAL);
			double  *start_of_output;
			start_of_output = (double *)mxGetPr(plhs[0]);
			memcpy(start_of_output, output, g_numCh*sizeof(double)*count);
			
			delete[] output;
			
		
	}
	// function case 3 and 4
		else if(nrhs==1&&nlhs>1 && mxIsStruct(prhs[0])) {

			bool isDone = false;
			WaitForSingleObject(ghMutexData, INFINITE );
			int preCount=gDataQueue.size();
			ReleaseMutex( ghMutexData);
			
			
			g_Fs=FREQ;
			mxArray* fs = mxGetField(prhs[0], 0,FIELD_Freq);
			if(fs) 
			{
				double* t= (double*)mxGetData(fs);
				g_Fs = *t;	
			}
			
			int factor=1;
			if(g_Fs<FREQ) {
				
				if(FREQ%((int)g_Fs)!=0)
					mexErrMsgTxt("Base Frequency not dividable by state.fs");
				else
					factor=(int)(FREQ/((int)g_Fs));
			}
			
			if(preCount>factor-1)
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
					//mexmexPrintf("%s\n",output3[i]);
				}

				int count = gDataQueue.size()/factor;
				
				double* output = new double[count*g_numCh];

				
				unsigned long long* dataTime = new unsigned long long[count];
				

				
				for(int i=0;i<count;i++) {
					

					chData newData;
					for(int j=0;j<g_numCh;j++)
						newData.channels[j] = 0;
					
					newData.timeStamp = gDataQueue.front().timeStamp;

					if(g_PolicyMean) 
					{
						for(int j=0; j<factor;j++) {
							chData temp = gDataQueue.front();
							for(int k=0; k<g_numCh; k++)
								newData.channels[k] += temp.channels[k]/factor;
							gDataQueue.pop();
						}
						
					}
					else 
					{
						chData temp = gDataQueue.front();
						
						for(int j=0; j<g_numCh; j++) 
						{
							newData.channels[j] = temp.channels[j];
						}

						for(int j=0; j<factor;j++) 
							gDataQueue.pop();

					}
					
					for(int j=0;j<g_numCh;j++)
					{
						output[j*count+i] = (newData.channels[j]); 
					}


						

					dataTime[i] = (unsigned long long)newData.timeStamp;
				}
				
				
				
				unsigned long long startTime = dataTime[0];
				
				if(g_PolicyMean) 
				{
					for(int i=0;i<count_markers;i++)
					{
						// mexmexPrintf("\nStart time:%lld\n",startTime);
						unsigned long long diff = (allMarkers[i].timeStamp - startTime)*FREQ/1000;
						
	//					fprintf(g_Fp, "%lld\n",diff);
						if(startTime>allMarkers[i].timeStamp)
						{	
							diff = 0;
						}
						if(allMarkers[i].timeStamp > dataTime[count-1])
							diff = dataTime[count-1];
						
						diff=diff/factor;
						if(diff > (count-1))
							diff = count - 1;
						output2[i] = diff;
					}
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
				for(int i=0;i<count_markers;i++)
				{
					string s(&output3[i][1]);
					istringstream(s) >> output4[i];
				}
				start_of_output = (double *)mxGetPr(plhs[2]);
				memcpy(start_of_output, output4, sizeof(double)*count_markers);
				
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
				Sleep(1);
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
	// Close
	else if(nlhs==0&&nrhs==1)
	{
		quitTMSI();
	}
}


void quitTMSI() {
	if(g_bIsConnected) {
		//TerminateThread(hServerThread,0);
		sockaddr_in si_other;
		SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
		memset((char*) &si_other,0,sizeof(si_other));
		si_other.sin_family = AF_INET;
		si_other.sin_port = htons(1206);
		si_other.sin_addr.S_un.S_addr = inet_addr("127.0.0.1");
		char quitmsg[] = "QUIT_CALLED";
		int slen = sizeof(si_other);
		sendto(s,quitmsg, strlen(quitmsg),0, (sockaddr*) &si_other, slen);
		
		CloseHandle(hServerThread);
			//TerminateThread(hObtainThread,0);
		bTerminate=true;
		Sleep(1000);
		CloseHandle(hObtainThread);
		closesocket(markerPassiveSocket);
				
			
		WaitForSingleObject(ghMutexData, INFINITE );
		WaitForSingleObject(ghMutexMarkers, INFINITE );
		
		g_bIsConnected = false;
		g_numCh = 8;
		g_PolicyMean=1;
		
		gDataQueue = queue<chData>();
		gMarkerQueue = queue<markerData>();
		ReleaseMutex( ghMutexMarkers);
		ReleaseMutex( ghMutexData);
		
		if(g_Handle) {
			fpStop(g_Handle);
			fpClose(g_Handle);
			Sleep(1000);
		}
		
		if( DeviceList != NULL ) 
			fpFreeDeviceList( g_Handle, NrOfDevices, DeviceList );
			
		DeviceList = NULL;
		if(g_Handle) {
			fpLibraryExit( g_Handle );
			g_Handle = NULL;
		}
			
		if(g_LibHandle) {
			FreeLibrary(g_LibHandle);
			g_LibHandle = NULL;
		}
	}
}