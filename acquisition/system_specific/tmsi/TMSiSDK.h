/*
Copyright (c) 2010 TMSi B.V.
All rights reserved.

WARNING: Please use the copy of this file which can be found on the Driver CD 
which was included with your TMSi frontend.
*/



#ifndef __TMSISDK_H__
#define __TMSISDK_H__


// Measurement modes:
#define MEASURE_MODE_NORMAL			((ULONG)0x0)
#define MEASURE_MODE_IMPEDANCE		((ULONG)0x1)
#define MEASURE_MODE_CALIBRATION	((ULONG)0x2)

#define MEASURE_MODE_IMPEDANCE_EX	((ULONG)0x3)
#define MEASURE_MODE_CALIBRATION_EX	((ULONG)0x4)

// for MEASURE_MODE_IMPEDANCE:
#define IC_OHM_002	0 /*!< 2K Impedance limit */
#define IC_OHM_005	1 /*!<  5K Impedance limit */
#define IC_OHM_010	2 /*!<  10K Impedance limit */
#define IC_OHM_020	3 /*!<  20K Impedance limit */
#define IC_OHM_050	4 /*!<  50K Impedance limit */
#define IC_OHM_100	5 /*!<  100K Impedance limit */
#define IC_OHM_200	6 /*!<  200K Impedance limit */

// for MEASURE_MODE_CALIBRATION:
#define IC_VOLT_050 0	/*!< 50 uV t-t Calibration voltage */
#define IC_VOLT_100 1	/*!< 100 uV t-t Calibration voltage */
#define IC_VOLT_200 2	/*!< 200 uV t-t Calibration voltage */
#define IC_VOLT_500 3	/*!< 500 uV t-t Calibration voltage */

 // for Signat Format
#define SF_UNSIGNED 0x0   // Unsigned integer 
#define SF_INTEGER  0x1	  // signed integer

// integer overflow value for analog channels
#define OVERFLOW_32BITS ((long) 0x80000000)
// Get Signal info

#define SIGNAL_NAME 40


// Unit defines
#define UNIT_UNKNOWN 0	// Used for digital inputs or if the driver cannot determine the units of a channel 
#define UNIT_VOLT 1		// Channel measures voltage 
#define UNIT_PERCENT 2	// Channel measures a percentage 
#define UNIT_BPM 3		// Beats per minute 
#define UNIT_BAR 4		// Pressure in bar 
#define UNIT_PSI 5		// Pressure in psi 
#define UNIT_MH20 6		// Pressure calibrated to meters water 
#define UNIT_MHG 7		// Pressure calibrated to meters mercury 
#define UNIT_BIT 8		// Used for digital inputs 

typedef struct _SIGNAL_FORMAT
{
	ULONG Size;		 // Size of this structure
	ULONG Elements;	 // Number of elements in list
	
	ULONG Type;		 // One of the signal types above 
	ULONG SubType;	 // One of the signal sub-types above
	ULONG Format;    // Float / Integer / Asci / Ect..
	ULONG Bytes;	 // Number of bytes per sample including subsignals

	FLOAT UnitGain;		  
	FLOAT UnitOffSet; 
	ULONG UnitId;			
	LONG UnitExponent; 

	WCHAR Name[SIGNAL_NAME]; 

	ULONG Port; 
	WCHAR PortName[SIGNAL_NAME]; 
	ULONG SerialNumber; 

}SIGNAL_FORMAT, *PSIGNAL_FORMAT; 

/**
@brief This structure contains information about the possible configuration of the frontend
**/
typedef struct _FRONTENDINFO 
{	unsigned short NrOfChannels;	/*!<  Current number of channels used */
	unsigned short SampleRateSetting;	/*!<  Current sample rate setting (a.k.a. base sample rate divider ) */
	unsigned short Mode;		/*!<  operating mode */
	unsigned short maxRS232;
	unsigned long Serial;    	/*!<  Serial number */
	unsigned short NrExg;       /*!<  Number of Exg channels in this device */
	unsigned short NrAux;		/*!<  Number of Aux channels in this device */
	unsigned short HwVersion;	/*!<  Version number for the hardware */
	unsigned short SwVersion;	/*!<  Version number of the embedded software */
	unsigned short RecBufSize;	/*!<  Used for debugging only */
	unsigned short SendBufSize;	/*!<  Used for debugging only */
	unsigned short NrOfSwChannels;   /*!<  Max. number of channels supported by this device */
	unsigned short BaseSf;		/*!<  Max. sample frequency */
	unsigned short Power; 
	unsigned short Check;		
}FRONTENDINFO,*PFRONTENDINFO; 


// Enum defined based on the communication methods from TMSiExtFrontendInfoType
typedef enum _TMSiConnectionEnum {
	TMSiConnectionUndefined = 0,	/*!< Undefined connection, indicates programming error */
	TMSiConnectionFiber,			/*!< USB 2.0 connection, used for fiber */
	TMSiConnectionBluetooth,		/*!< Bluetooth connection with Microsoft driver */
	TMSiConnectionUSB,			/*!< USB 2.0 connection direct */
	TMSiConnectionWifi,			/*!< Network connection, Ip-adress and port needed, wireless */
	TMSiConnectionNetwork		/*!< Network connection, Ip-adress and port needed, wired */
} TMSiConnectionType;

typedef enum _TmsiErrorCodeEnum { 
	TMSiErrorCodeUnsuccessfull = 256,	/*!< When something undefined went wrong */
	TMSiErrorCodeInvalidHandle,	/*!< The handle given to the function is not valid */
	TMSiErrorCodeNotImplemented /* !< When the functionality is not implemented */

} TmsiErrorCodeType ;

BOOLEAN APIENTRY SetRtcTime(IN HANDLE Handle,IN SYSTEMTIME *InTime );
BOOLEAN APIENTRY GetRtcTime(IN HANDLE Handle,IN SYSTEMTIME *InTime );
BOOLEAN APIENTRY SetRtcAlarmTime(IN HANDLE Handle,IN SYSTEMTIME *InTime, IN BOOLEAN AlarmOnOff );
BOOLEAN APIENTRY GetRtcAlarmTime(IN HANDLE Handle,IN SYSTEMTIME *InTime, IN BOOLEAN *AlarmOnOff );
int APIENTRY TMSISendDataBlock(IN HANDLE Handle, int KeyCode, 
										   unsigned short BlockType, 
										   unsigned short NrOfShorts, 
										   const short* const InBuffer, 
										   unsigned short ExpectedBlockType );

HANDLE APIENTRY LibraryInit( TMSiConnectionType GivenConnectionType, int *ErrorCode );
int APIENTRY LibraryExit(HANDLE Handle);

BOOLEAN APIENTRY GetFrontEndInfo( IN HANDLE Handle, IN OUT FRONTENDINFO *FrontEndInfo );
int APIENTRY GetErrorCode( IN HANDLE Handle ) ;
const char* APIENTRY GetErrorCodeMessage( HANDLE Handle, int id );




/* Additional types and constants used by feature.cpp */ 

typedef struct _FeatureData
{	ULONG Id;		/* Feature ID */ 
	ULONG Info;		/* Feature dependend information */  
}FEATURE_DATA, *PFEATURE_DATA;

//----------- TYPE ---------------------

#define CHANNELTYPE_UNKNOWN 0
#define CHANNELTYPE_EXG 1
#define CHANNELTYPE_BIP 2
#define CHANNELTYPE_AUX 3
#define CHANNELTYPE_DIG 4
#define CHANNELTYPE_TIME 5
#define CHANNELTYPE_LEAK 6
#define CHANNELTYPE_PRESSURE 7
#define CHANNELTYPE_ENVELOPE 8
#define CHANNELTYPE_MARKER 9
#define CHANNELTYPE_SAW 10
#define CHANNELTYPE_SAO2 11

/* Deprecated define for feature mode. Do not use them! */
#define DEVICE_FEATURE_MODE		    0x0302
#define DEVICE_FEATURE_RTC		    0x0301

//Commands reserved for tmsi only
#define DEVICE_FEATURE_DSP_COMMAND  0x0100
#define DEVICE_FEATURE_REF			0x0101
#define DEVICE_FEATURE_RAW			0x0222
#define DEVICE_FEATURE_CORRECTION	0x0503

// New for Refa-MS
#define DEVICE_FEATURE_SETCOMREFCHAN    0x0021


#define MAX_SAMPLE_RATE 0xFFFFFFFF
#define MAX_BUFFER_SIZE 0xFFFFFFFF

#define MAX_FRONTENDNAME_LENGTH 256

#define CRC_ERRORCODE_IN_ACKNOWLEDGE 0x02

/**
@brief Mobita specific: This structure contains the TDF File Info which is used to build a list 
of stored files on the internal storage
**/
typedef struct TMSiFileInfo
{
	unsigned short	 FileID;	/*!< Unique file number identifying the file. */
	SYSTEMTIME	StartRecTime;	/*!< The start time of the recording */
	SYSTEMTIME	StopRecTime;	/*!< The stop time of the recording */
}TMSiFileInfoType;

#define MAX_PATIENTID_LENGTH 128
#define MAX_USERSTRING_LENGTH 64

/**
@brief Mobita specific: This structure contains the TDF File Header which is used for each 
stored file on the internal storage
**/
typedef struct TMSiTDFHeader		// Detailed description can be found in the TDF spec document.
{
	unsigned int		NumberOfSamp;		/*!< Number of samples in the file */
	SYSTEMTIME			StartRecTime;		/*!< Time on which the recording is started */
	SYSTEMTIME			EndRecTime;			/*!< Time on which the recording is stopped */
	unsigned int		FrontEndSN;			/*!< Serial number of the frontend */
	unsigned int		FrontEndAdpSN;		/*!< Serial number of the attached head during recording */
	unsigned short		FrontEndHWVer;		/*!< Hardware version of the frontend */
	unsigned short		FrontEndSWVer;		/*!< Firmware version of the frontend */
	unsigned short		FrontEndAdpHWVer;	/*!< Hardware version of the attached head */
	unsigned short		FrontEndAdpSWVer;	/*!< Firmware version of the attached head */
	unsigned short		ADCSampRate;		/*!< Maximal samplerate of the frontend */
	char				PatientID[MAX_PATIENTID_LENGTH]; 	/*!< Patient information string copied from the configuration */
	char				UserString1[MAX_USERSTRING_LENGTH];	/*!< Information string copied from the configuration */
} TMSiFileHeaderType;

/**
@brief Mobita specific: Enum for all possible flags of the StartControl field
**/
typedef enum _TMSiStartControl {
	sc_man_shutdown_enable = 256	,
	sc_rf_recurring	= 128,
	sc_rf_timed_start = 64,
	sc_rf_auto_start = 32,
	sc_alarm_recurring = 16,
	sc_power_on_record_auto_start = 8,
	sc_man_record_enable = 4,
	sc_alarm_record_auto_start = 2,
	sc_rtc_set =1
} TMSiStartControlType;

#define MAX_MEASUREFILENAME_LENGTH 32
/**
@brief Mobita specific: This structure contains the TDF Recording Config which is to configure the Mobita 
for timed recording from the PC, and for returning information about a configuration on the Mobita
**/
typedef struct TMSiRecordingConfig	// Detailed description can be found in the TDF spec document.
{
	unsigned short		StorageType; /*!< Set by user. If bit0 is set, then the data as it would be sent over the wireless/USB/Fiber connection will be stored in the measurement file. */
	unsigned short		ADCSampRate;/*!< Maximal samplerate of the frontend */
	unsigned short		NumberOfChan;/*!< This value contains the sum of storable channels, ExG, Aux, Bip etc (hardware)  and  Digi, SaO2, 3D etc. (software) that are available to the front-end.  */
	TMSiStartControlType StartControl; /*!< Set by user. This enum consists of a number of bits that control the startup behaviour of the system. */
	unsigned int		EndControl;/*!< See TDF document or TMSiSDK.chm */
	unsigned int		CardStatus;/*!< 0x00000001 Formatted, 0x00000002 Filled, 0x00000003 Full, 0x7FFFFFFF Error, 0xFFFFFFFF Default */
	char				MeasureFileName[MAX_MEASUREFILENAME_LENGTH];/*!< The TMSI system uses these fields to name the measurement files that are made.  All characters are printable ASCII characters. The default name is: YYYYMMDD_HHMMSS.tdf */
	SYSTEMTIME		AlarmTimeStart;/*!< Set by user. Start recording at the configured time when bit 0 or bit 1 is set in the field START CONTROL */
	SYSTEMTIME		AlarmTimeStop;/*!<  Set by user. Stop recording at the configured time when bit 0 or bit 1 is set in the field START CONTROL */
	SYSTEMTIME		AlarmTimeInterval;/*!< Set by user. The alarm repetition interval is relative to the ALARM TIMESTART and must be larger than the time difference : ALARMTIMESTOP – ALARMTIMESTART. */
	unsigned int		AlarmTimeCount;/*!< Set by user. The alarm repetition count is decreased every Alarm repetition interval, till it is zero. */
	unsigned int		FrontEndSN;/*!< Serial number of the frontend */
	unsigned int		FrontEndAdpSN;/*!<  Serial number of the Adapter connected to the Mobita during the measurement */
	unsigned int		RecordCondition;/*!< Set by user. Must be zero for now */
	SYSTEMTIME		RFInterfStartTime;	/*!< Set by user. Start time of the Radio communication interface */
	SYSTEMTIME		RFInterfStopTime;	/*!< Set by user. Stop time of the Radio communication interface */
	SYSTEMTIME		RFInterfInterval;	/*!< Set by user. Time Interval of the Radio communication interface */
	unsigned int		RFInterfCount;						/*!< Number of times the Radio communication interface is turned on */
	char				PatientID[MAX_PATIENTID_LENGTH];	/*!< Set by user. Patient identifier */
	char				UserString1[MAX_USERSTRING_LENGTH]; /*!< Set by user. User/Application specific string */
} TMSiRecordingConfigType;

/**
@brief Mobita specific: This structure contains information about the current battery state
**/
typedef struct TMSiBatReport {
	short Temp;					/*!<  Battery temperatur in degree Celsius (°C) */
	short Voltage; 				/*!<  Battery Voltage in milliVolt  (mV) */
	short Current;				/*!<  Battery Current in milliAmpere (mA) */
	short AccumCurrent; 		/*!<  Battery Accumulated Current in milliAmpere (mA) */
	short AvailableCapacityInPercent; /*!<  Available battery Capacity In Percent, range 0-100 */
	unsigned short  DoNotUse1;	/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse2;	/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse3;	/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse4;	/*!<  Do not use, reserved for future use */
} TMSiBatReportType;

/**
@brief Mobita specific: This structure contains information about the current state of the internal storage
**/
typedef struct TMSiStorageReport 
{
	unsigned int	StructSize;		/*!<  Size of struct in words */
	unsigned int 	TotalSize; 		/*!<  Total size of the internal storage in MByte (=1024x1024 bytes) */
	unsigned int 	UsedSpace;		/*!<  Used space on the internal storage in MByte (=1024x1024 bytes)*/
	unsigned int	SDCardCID[4];	/*!<  The CID register of the current SD-Card. */
	unsigned short	DoNotUse1;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse2;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse3;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse4;		/*!<  Do not use, reserved for future use */
} TMSiStorageReportType;

/**
@brief Mobita specific: This structure contains information about the current and past use of the Mobita
**/
typedef struct TMSiDeviceReport
{
	unsigned int	AdapterSN;		/*!<  Serial number of the current connected Adapter */
	unsigned int	AdapterStatus;	/*!<  0=Unknown; 1=Ok;2=MemError */
	unsigned int	AdapterCycles;	/*!<  Number of connections made by the Adapter. */
	unsigned int	MobitaSN;		/*!<  Serial number of the Mobita */
	unsigned int	MobitaStatus;	/*!<  Statis of the Mobita : 0=Unknown; 1=Ok;2=MemError;3=BatError; */
	unsigned int	MobitaCycles;	/*!<  Number of adapter connections made by the Mobita */
	unsigned short	DoNotUse1;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse2;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse3;		/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse4;		/*!<  Do not use, reserved for future use */
} TMSiDeviceReportType;

/**
@brief Mobita specific: This structure contains information about the current sampling configuration
**/
typedef struct TMSiExtFrontendInfo
{
	unsigned short	CurrentSamplerate;	/*!<  in Hz */
	unsigned short	CurrentInterface;   /*!<  0 = Unknown; 1 = Fiber;  2 = Bluetooth; 3 = USB; 4 = WiFi; 5 = Network*/
	unsigned short	CurrentBlockType; 	/*!<  The blocktype used to send sample data for the selected CurrentFs and selected CurrentInterface */
	unsigned short	DoNotUse1;			/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse2;			/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse3;			/*!<  Do not use, reserved for future use */
	unsigned short	DoNotUse4;			/*!<  Do not use, reserved for future use */
} TMSiExtFrontendInfoType;


/* Function prototypes */
TMSiFileInfoType* APIENTRY GetCardFileList(void *Handle, int *NrOfFiles );
BOOLEAN APIENTRY OpenCardFile(void *Handle, unsigned short FileId, TMSiFileHeaderType* FileHeader );
PSIGNAL_FORMAT APIENTRY GetCardFileSignalFormat(IN HANDLE Handle );
BOOLEAN APIENTRY SetRecordingConfiguration(void *Handle, TMSiRecordingConfigType *RecordingConfig, unsigned int *ChannelConfig, unsigned int NrOfChannels );
BOOLEAN APIENTRY GetRecordingConfiguration(void *Handle, TMSiRecordingConfigType *RecordingConfig, unsigned int *ChannelConfig, unsigned int *NrOfChannels );


BOOLEAN			APIENTRY ResetDevice	(IN HANDLE Handle);
BOOLEAN			APIENTRY Open			(void *Handle, const char *DeviceLocator );
BOOLEAN			APIENTRY Close			(HANDLE hHandle);
BOOLEAN			APIENTRY Start			(IN HANDLE Handle);
BOOLEAN			APIENTRY Stop			(IN HANDLE Handle);
BOOLEAN			APIENTRY SetSignalBuffer(IN HANDLE Handle,IN OUT PULONG SampleRate,IN OUT PULONG BufferSize);
BOOLEAN			APIENTRY GetBufferInfo	(IN HANDLE Handle,OUT PULONG Overflow,OUT PULONG PercentFull);
LONG			APIENTRY GetSamples		(IN HANDLE Handle,OUT PULONG SampleBuffer,IN ULONG Size);
BOOLEAN			APIENTRY DeviceFeature(IN HANDLE Handle,IN LPVOID DataIn, IN DWORD InSize ,IN LPVOID DataOut, IN DWORD OutSize );
PSIGNAL_FORMAT	APIENTRY GetSignalFormat (IN HANDLE Handle, IN OUT char* FrontEndName );

BOOLEAN			APIENTRY Free		    ( IN VOID *Memory );
HANDLE			APIENTRY LibraryInit	( TMSiConnectionType GivenConnectionType, int *ErrorCode );
int				APIENTRY LibraryExit	( HANDLE Handle);
BOOLEAN			APIENTRY GetFrontEndInfo( IN HANDLE Handle, IN OUT FRONTENDINFO *FrontEndInfo );
BOOLEAN			APIENTRY SetRtcTime		( IN HANDLE Handle,IN SYSTEMTIME *InTime );
int				APIENTRY GetErrorCode( IN HANDLE Handle );
const char*		APIENTRY GetErrorCodeMessage( IN HANDLE Handle, IN int ErrorCode );
char**	APIENTRY GetDeviceList	( HANDLE Handle, int *NrOfFrontEnds);
void			APIENTRY FreeDeviceList( HANDLE Handle, int NrOfFrontEnds, char** DeviceList );
BOOLEAN APIENTRY GetConnectionProperties( IN HANDLE Handle, IN OUT int *SignalStrength, 
									   IN OUT unsigned int *NrOfCRCErrors, IN OUT unsigned int *NrOfSampleBlocks );
BOOLEAN APIENTRY StartCardFile(void *Handle );
BOOLEAN APIENTRY StopCardFile(void *Handle );
BOOLEAN APIENTRY CloseCardFile(void *Handle );
LONG APIENTRY GetCardFileSamples(IN HANDLE Handle,OUT PULONG SampleBuffer,IN ULONG SampleBufferSizeInBytes);
BOOLEAN APIENTRY SetRefCalculation(IN HANDLE Handle, int OnOrOff );
BOOLEAN APIENTRY SetMeasuringMode(IN HANDLE Handle,IN ULONG Mode, IN int Value );
BOOLEAN APIENTRY GetExtFrontEndInfo( IN HANDLE Handle, IN OUT TMSiExtFrontendInfoType *ExtFrontEndInfo,
									TMSiBatReportType *BatteryReport, 
									TMSiStorageReportType *StorageReport,
									TMSiDeviceReportType *DeviceReport );
const char* APIENTRY GetRevision( IN HANDLE Handle );
BOOLEAN APIENTRY ConvertSignalFormat(IN HANDLE Handle, IN SIGNAL_FORMAT *psf,
									 IN unsigned int Index,
									 IN OUT int *Size,
									 IN OUT int *Format,
									 IN OUT int *Type,
									 IN OUT int *SubType, 
									 IN OUT float *UnitGain, 
									 IN OUT float *UnitOffSet,
									 IN OUT int *UnitId, 
									 IN OUT int *UnitExponent,
									 IN OUT char Name[SIGNAL_NAME] );

int APIENTRY TMSIRawData(IN HANDLE Handle, int KeyCode, 
						 unsigned short NrOfShortsIn, 
						 const short* const InBuffer, 
						 unsigned short ExpectedBlockType,
						 unsigned short *NrOfShortsOut, 
						 short* OutBuffer );

// NeXus10MkII functionality
BOOLEAN APIENTRY GetRandomKey(void *Handle, char *Key, unsigned int *LengthKeyInBytes );
BOOLEAN APIENTRY UnlockFrontEnd(void *Handle, char *Key, unsigned int *LengthKeyInBytes );
BOOLEAN APIENTRY GetOEMSize(void *Handle, unsigned int *LengthInBytes );
BOOLEAN APIENTRY SetOEMData(IN HANDLE Handle,
										const char *BinaryOEMData,
										const unsigned int OEMDataLengthInBytes );

BOOLEAN APIENTRY GetOEMData(IN HANDLE Handle,
										IN OUT char *BinaryOEMData,
										IN OUT unsigned int *OEMDataLengthInBytes );
BOOLEAN APIENTRY OpenFirstDevice( HANDLE Handle );
BOOLEAN APIENTRY SetStorageMode(IN HANDLE Handle, int OnOrOff );

#ifndef NO_DLL_PROTO
typedef BOOLEAN			( __stdcall * PRESET)			(IN HANDLE Handle) ;
typedef BOOLEAN			( __stdcall * POPEN	)			(void *Handle, const char *DeviceLocator );
typedef BOOLEAN			( __stdcall * PCLOSE ) 			(HANDLE hHandle);
typedef BOOLEAN			( __stdcall * PSTART)			(IN HANDLE Handle);
typedef BOOLEAN			( __stdcall * PSTOP)  			(IN HANDLE Handle);
typedef BOOLEAN			( __stdcall * PSETSIGNALBUFFER)	(IN HANDLE Handle,IN OUT PULONG SampleRate,IN OUT PULONG BufferSize);
typedef BOOLEAN			( __stdcall * PGETBUFFERINFO)	(IN HANDLE Handle,OUT PULONG Overflow,OUT PULONG PercentFull);
typedef LONG			( __stdcall * PGETSAMPLES)		(IN HANDLE Handle,OUT PULONG SampleBuffer,IN ULONG Size);
typedef BOOLEAN			( __stdcall * PDEVICEFEATURE)		(IN HANDLE Handle,IN LPVOID DataIn, IN DWORD InSize ,OUT LPVOID DataOut, IN DWORD OutSize );
typedef PSIGNAL_FORMAT	( __stdcall * PGETSIGNALFORMAT)     (IN HANDLE Handle, IN OUT char* FrontEndName); 
typedef BOOLEAN			( __stdcall * PFREE)			(IN VOID *Memory); 
typedef HANDLE			( __stdcall * PLIBRARYINIT)		(IN TMSiConnectionType GivenConnectionType, IN OUT int *ErrorCode );
typedef int				( __stdcall * PLIBRARYEXIT)		(IN HANDLE Handle);
typedef BOOLEAN			( __stdcall * PGETFRONTENDINFO)	(IN HANDLE Handle, IN OUT FRONTENDINFO *FrontEndInfo );
typedef BOOLEAN			( __stdcall * PSETRTCTIME)		(IN HANDLE Handle,IN SYSTEMTIME *InTime );
typedef BOOLEAN			( __stdcall * PGETRTCTIME)		(IN HANDLE Handle,IN SYSTEMTIME *InTime );
typedef BOOLEAN			( __stdcall * PSETRTCALARMTIME)	(HANDLE Handle, SYSTEMTIME *InTime, BOOLEAN AlarmOnOff  );
typedef BOOLEAN			( __stdcall * PGETRTCALARMTIME)	(HANDLE Handle, SYSTEMTIME *InTime, BOOLEAN *AlarmOnOff  );
typedef int				( __stdcall * PGETERRORCODE)	( IN HANDLE Handle );
typedef const char*		( __stdcall * PGETERRORCODEMESSAGE)( IN HANDLE Handle, IN int ErrorCode );
typedef char**			( __stdcall * PGETDEVICELIST)		( IN HANDLE Handle, IN OUT int *NrOfFrontEnds);
typedef void			( __stdcall * PFREEDEVICELIST)	( HANDLE Handle, int NrOfFrontEnds, char** DeviceList );
typedef BOOLEAN			( __stdcall * PGETCONNECTIONPROPERTIES)( IN HANDLE Handle, IN OUT unsigned int *SignalStrength, 
									   IN OUT unsigned int *NrOfCRCErrors, IN OUT unsigned int *NrOfSampleBlocks ); 
typedef BOOLEAN			( __stdcall * PSTARTCARDFILE)	(void *Handle );
typedef BOOLEAN			( __stdcall * PSTOPCARDFILE)	(void *Handle );
typedef LONG			( __stdcall * PGETCARDFILESAMPLES)	(IN HANDLE Handle,OUT PULONG SampleBuffer,IN ULONG SampleBufferSizeInBytes);
typedef BOOLEAN			( __stdcall * PSETREFCALCULATION)(IN HANDLE Handle, int OnOrOff );
typedef BOOLEAN			( __stdcall * PSETMEASURINGMODE)(IN HANDLE Handle,IN ULONG Mode, IN int Value );
typedef PSIGNAL_FORMAT	( __stdcall * PGETCARDFILESIGNALFORMAT)(IN HANDLE Handle );
typedef BOOLEAN			( __stdcall * POPENCARDFILE)(void *Handle, unsigned short FileId, TMSiFileHeaderType* FileHeader );
typedef TMSiFileInfoType* ( __stdcall * PGETCARDFILELIST)(void *Handle, int *NrOfFiles );
typedef BOOLEAN			( __stdcall * PCLOSECARDFILE)(void *Handle );
typedef BOOLEAN			( __stdcall * PSETRECORDINGCONFIGURATION)(void *Handle, TMSiRecordingConfigType *RecordingConfig, unsigned int *ChannelConfig, unsigned int NrOfChannels );
typedef BOOLEAN			( __stdcall * PGETRECORDINGCONFIGURATION)(void *Handle, TMSiRecordingConfigType *RecordingConfig, unsigned int *ChannelConfig, unsigned int *NrOfChannels );
typedef BOOLEAN			( __stdcall * PGETEXTFRONTENDINFO)( IN HANDLE Handle, IN OUT TMSiExtFrontendInfoType *ExtFrontEndInfo,
									TMSiBatReportType *BatteryReport, 
									TMSiStorageReportType *StorageReport,
									TMSiDeviceReportType *DeviceReport );
typedef int				( __stdcall * PTMSISENDDATABLOCK)(IN HANDLE Handle, int KeyCode, 
										   unsigned short BlockType, 
										   unsigned short NrOfShorts, 
										   const short* const InBuffer, 
										   unsigned short ExpectedBlockType );
typedef const char*		( __stdcall * PGETREV)( IN HANDLE Handle );

typedef BOOLEAN			( __stdcall * PCONVERTSIGNALFORMAT)( HANDLE Handle, SIGNAL_FORMAT *psf,
									 unsigned int Index,
									 int *Size,
									 int *Format,
									 int *Type,
									 int *SubType, 
									 float *UnitGain, 
									 float *UnitOffSet,
									 int *UnitId, 
									 int *UnitExponent,
									 char Name[SIGNAL_NAME] );

typedef int				( __stdcall * PTMSIRAWDATA)(IN HANDLE Handle, int KeyCode, 
													unsigned short NrOfShortsIn, 
													const short* const InBuffer, 
													unsigned short ExpectedBlockType,
													unsigned short *NrOfShortsOut, 
													short* OutBuffer );

// NeXus10MkII functionality
typedef BOOLEAN ( __stdcall * PGETRANDOMKEY)(void *Handle, char *Key, unsigned int *LengthKeyInBytes );
typedef BOOLEAN ( __stdcall * PUNLOCKFRONTEND)(void *Handle, char *Key, unsigned int *LengthKeyInBytes );
typedef BOOLEAN ( __stdcall * PGETOEMSIZE) (void *Handle, unsigned int *LengthInBytes ); 
typedef BOOLEAN ( __stdcall * PSETOEMDATA)(IN HANDLE Handle,
										const char *BinaryOEMData,
										const unsigned int OEMDataLengthInBytes );

typedef BOOLEAN ( __stdcall * PGETOEMDATA)(IN HANDLE Handle,
										IN OUT char *BinaryOEMData,
										IN OUT unsigned int *OEMDataLengthInBytes );
typedef BOOLEAN ( __stdcall * POPENFIRSTDEVICE)( HANDLE Handle );
typedef BOOLEAN ( __stdcall * PSETSTORAGEMODE)(IN HANDLE Handle, int OnOrOff );

#endif //NO_DLL_PROTO


#endif //__TMSISDK_H__