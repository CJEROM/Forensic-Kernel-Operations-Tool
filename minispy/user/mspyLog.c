/*++

Copyright (c) 1989-2002  Microsoft Corporation

Module Name:

    mspyLog.c

Abstract:

    This module contains functions used to retrieve and see the log records
    recorded by MiniSpy.sys.

Environment:

    User mode

--*/

#include <DriverSpecs.h>
_Analysis_mode_(_Analysis_code_type_user_code_)

#include <stdio.h>
#include <windows.h>
#include <stdlib.h>
#include <winioctl.h>
#include "mspyLog.h"

#include <sqlite3.h>
#include <time.h>

#define TIME_BUFFER_LENGTH 20
#define TIME_ERROR         "time error"

#define POLL_INTERVAL   200     // 200 milliseconds

BOOLEAN
TranslateFileTag(
    _In_ PLOG_RECORD logRecord
    )
/*++

Routine Description:

    If this is a mount point reparse point, move the given name string to the
    correct position in the log record structure so it will be displayed
    by the common routines.

Arguments:

    logRecord - The log record to update

Return Value:

    TRUE - if this is a mount point reparse point
    FALSE - otherwise

--*/
{
    PFLT_TAG_DATA_BUFFER TagData;
    ULONG Length;

    //
    // The reparse data structure starts in the NAME field, point to it.
    //

    TagData = (PFLT_TAG_DATA_BUFFER) &logRecord->Name[0];

    //
    //  See if MOUNT POINT tag
    //

    if (TagData->FileTag == IO_REPARSE_TAG_MOUNT_POINT) {

        //
        //  calculate how much to copy
        //

        Length = min( MAX_NAME_SPACE - sizeof(UNICODE_NULL), TagData->MountPointReparseBuffer.SubstituteNameLength );

        //
        //  Position the reparse name at the proper position in the buffer.
        //  Note that we are doing an overlapped copy
        //

        MoveMemory( &logRecord->Name[0],
                    TagData->MountPointReparseBuffer.PathBuffer,
                    Length );

        logRecord->Name[Length/sizeof(WCHAR)] = UNICODE_NULL;
        return TRUE;
    }

    return FALSE;
}


DWORD
WINAPI
RetrieveLogRecords(
    _In_ LPVOID lpParameter
    )
/*++

Routine Description:

    This runs as a separate thread.  Its job is to retrieve log records
    from the filter and then output them

Arguments:

    lpParameter - Contains context structure for synchronizing with the
        main program thread.

Return Value:

    The thread successfully terminated

--*/
{
    PLOG_CONTEXT context = (PLOG_CONTEXT)lpParameter;
    DWORD bytesReturned = 0;
    DWORD used;
    PVOID alignedBuffer[BUFFER_SIZE/sizeof( PVOID )];
    PCHAR buffer = (PCHAR) alignedBuffer;
    HRESULT hResult;
    PLOG_RECORD pLogRecord;
    PRECORD_DATA pRecordData;
    COMMAND_MESSAGE commandMessage;

    //printf("Log: Starting up\n");

#pragma warning(push)
#pragma warning(disable:4127) // conditional expression is constant

    while (TRUE) {

#pragma warning(pop)

        //
        //  Check to see if we should shut down.
        //

        if (context->CleaningUp) {

            break;
        }

        //
        //  Request log data from MiniSpy.
        //

        commandMessage.Command = GetMiniSpyLog;

        hResult = FilterSendMessage( context->Port,
                                     &commandMessage,
                                     sizeof( COMMAND_MESSAGE ),
                                     buffer,
                                     sizeof(alignedBuffer),
                                     &bytesReturned );

        if (IS_ERROR( hResult )) {

            if (HRESULT_FROM_WIN32( ERROR_INVALID_HANDLE ) == hResult) {

                printf( "The kernel component of minispy has unloaded. Exiting\n" );
                WriteAlertToDatabase("The kernel component of minispy has unloaded. Exiting");

                ExitProcess( 0 );
            } else {

                if (hResult != HRESULT_FROM_WIN32( ERROR_NO_MORE_ITEMS )) {

                    printf( "UNEXPECTED ERROR received: %x\n", hResult );
                    WriteAlertToDatabase("UNEXPECTED ERROR received: %x", hResult);
                }

                Sleep( POLL_INTERVAL );
            }

            continue;
        }

        //
        //  Buffer is filled with a series of LOG_RECORD structures, one
        //  right after another.  Each LOG_RECORD says how long it is, so
        //  we know where the next LOG_RECORD begins.
        //

        pLogRecord = (PLOG_RECORD) buffer;
        used = 0;

        //
        //  Logic to write record to screen and/or file
        //

        for (;;) {

            if (used+FIELD_OFFSET(LOG_RECORD,Name) > bytesReturned) {

                break;
            }

            if (pLogRecord->Length < (sizeof(LOG_RECORD)+sizeof(WCHAR))) {

                printf( "UNEXPECTED LOG_RECORD->Length: length=%d expected>=%d\n",
                        pLogRecord->Length,
                        (ULONG)(sizeof(LOG_RECORD)+sizeof(WCHAR)));
                WriteAlertToDatabase("UNEXPECTED LOG_RECORD->Length: length=%d expected>=%d", pLogRecord->Length, (ULONG)(sizeof(LOG_RECORD) + sizeof(WCHAR)));

                break;
            }

            used += pLogRecord->Length;

            if (used > bytesReturned) {

                printf( "UNEXPECTED LOG_RECORD size: used=%d bytesReturned=%d\n",
                        used,
                        bytesReturned);
                WriteAlertToDatabase("UNEXPECTED LOG_RECORD size: used=%d bytesReturned=%d", used, bytesReturned);

                break;
            }

            pRecordData = &pLogRecord->Data;

            //
            //  See if a reparse point entry
            //

            if (FlagOn(pLogRecord->RecordType,RECORD_TYPE_FILETAG)) {

                if (!TranslateFileTag( pLogRecord )){

                    //
                    // If this is a reparse point that can't be interpreted, move on.
                    //

                    pLogRecord = (PLOG_RECORD)Add2Ptr(pLogRecord,pLogRecord->Length);
                    continue;
                }
            }

            if (context->LogToScreen) {

                /*ScreenDump( pLogRecord->SequenceNumber,
                            pLogRecord->Name,
                            pRecordData );*/
            }

            if (context->LogToFile) {

                /*FileDump( pLogRecord->SequenceNumber,
                          pLogRecord->Name,
                          pRecordData,
                          context->OutputFile );*/

                DatabaseDump(
                    pLogRecord->SequenceNumber,
                    pLogRecord->Name,
                    pRecordData);
            }

            //
            //  The RecordType could also designate that we are out of memory
            //  or hit our program defined memory limit, so check for these
            //  cases.
            //

            if (FlagOn(pLogRecord->RecordType,RECORD_TYPE_FLAG_OUT_OF_MEMORY)) {

                if (context->LogToScreen) {

                    printf( "M:  %08X System Out of Memory\n",
                            pLogRecord->SequenceNumber );
                    
                }

                if (context->LogToFile) {

                    fprintf( context->OutputFile,
                             "M:\t0x%08X\tSystem Out of Memory\n",
                             pLogRecord->SequenceNumber );
                    WriteAlertToDatabase("M:\t0x%08X\tSystem Out of Memory", pLogRecord->SequenceNumber);
                }

            } else if (FlagOn(pLogRecord->RecordType,RECORD_TYPE_FLAG_EXCEED_MEMORY_ALLOWANCE)) {

                if (context->LogToScreen) {

                    printf( "M:  %08X Exceeded Mamimum Allowed Memory Buffers\n",
                            pLogRecord->SequenceNumber );
                }

                if (context->LogToFile) {

                    fprintf( context->OutputFile,
                             "M:\t0x%08X\tExceeded Mamimum Allowed Memory Buffers\n",
                             pLogRecord->SequenceNumber );
                    WriteAlertToDatabase("M:\t0x%08X\tExceeded Mamimum Allowed Memory Buffers", pLogRecord->SequenceNumber);
                }
            }

            //
            // Move to next LOG_RECORD
            //

            pLogRecord = (PLOG_RECORD)Add2Ptr(pLogRecord,pLogRecord->Length);
        }

        //
        //  If we didn't get any data, pause for 1/2 second
        //

        if (bytesReturned == 0) {

            Sleep( POLL_INTERVAL );
        }
    }

    printf( "Log: Shutting down\n" );
    WriteAlertToDatabase("Log: Shutting down");

    ReleaseSemaphore( context->ShutDown, 1, NULL );

    printf( "Log: All done\n" );
    WriteAlertToDatabase("Log: All done");

    return 0;
}


VOID
PrintIrpCode(
    _In_ UCHAR MajorCode,
    _In_ UCHAR MinorCode,
    _Out_ const CHAR** MajorStringOut,
    _Out_ const CHAR** MinorStringOut
)
/*++

Routine Description:

    Display the operation code

Arguments:

    MajorCode - Major function code of operation

    MinorCode - Minor function code of operation

    OutputFile - If writing to a file (not the screen) the handle for that file

    PrintMajorCode - Only used when printing to the display:
        TRUE - if we want to display the MAJOR CODE
        FALSE - if we want to display the MINOR code

Return Value:

    None

--*/
{
    CHAR *irpMajorString, *irpMinorString = NULL;
    CHAR errorBuf[128];

    switch (MajorCode) {
        case IRP_MJ_CREATE:
            irpMajorString = IRP_MJ_CREATE_STRING;
            break;
        case IRP_MJ_CREATE_NAMED_PIPE:
            irpMajorString = IRP_MJ_CREATE_NAMED_PIPE_STRING;
            break;
        case IRP_MJ_CLOSE:
            irpMajorString = IRP_MJ_CLOSE_STRING;
            break;
        case IRP_MJ_READ:
            irpMajorString = IRP_MJ_READ_STRING;
            switch (MinorCode) {
                case IRP_MN_NORMAL:
                    irpMinorString = IRP_MN_NORMAL_STRING;
                    break;
                case IRP_MN_DPC:
                    irpMinorString = IRP_MN_DPC_STRING;
                    break;
                case IRP_MN_MDL:
                    irpMinorString = IRP_MN_MDL_STRING;
                    break;
                case IRP_MN_COMPLETE:
                    irpMinorString = IRP_MN_COMPLETE_STRING;
                    break;
                case IRP_MN_COMPRESSED:
                    irpMinorString = IRP_MN_COMPRESSED_STRING;
                    break;
                case IRP_MN_MDL_DPC:
                    irpMinorString = IRP_MN_MDL_DPC_STRING;
                    break;
                case IRP_MN_COMPLETE_MDL:
                    irpMinorString = IRP_MN_COMPLETE_MDL_STRING;
                    break;
                case IRP_MN_COMPLETE_MDL_DPC:
                    irpMinorString = IRP_MN_COMPLETE_MDL_DPC_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_WRITE:
            irpMajorString = IRP_MJ_WRITE_STRING;
            switch (MinorCode) {
                case IRP_MN_NORMAL:
                    irpMinorString = IRP_MN_NORMAL_STRING;
                    break;
                case IRP_MN_DPC:
                    irpMinorString = IRP_MN_DPC_STRING;
                    break;
                case IRP_MN_MDL:
                    irpMinorString = IRP_MN_MDL_STRING;
                    break;
                case IRP_MN_COMPLETE:
                    irpMinorString = IRP_MN_COMPLETE_STRING;
                    break;
                case IRP_MN_COMPRESSED:
                    irpMinorString = IRP_MN_COMPRESSED_STRING;
                    break;
                case IRP_MN_MDL_DPC:
                    irpMinorString = IRP_MN_MDL_DPC_STRING;
                    break;
                case IRP_MN_COMPLETE_MDL:
                    irpMinorString = IRP_MN_COMPLETE_MDL_STRING;
                    break;
                case IRP_MN_COMPLETE_MDL_DPC:
                    irpMinorString = IRP_MN_COMPLETE_MDL_DPC_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_QUERY_INFORMATION:
            irpMajorString = IRP_MJ_QUERY_INFORMATION_STRING;
            break;
        case IRP_MJ_SET_INFORMATION:
            irpMajorString = IRP_MJ_SET_INFORMATION_STRING;
            break;
        case IRP_MJ_QUERY_EA:
            irpMajorString = IRP_MJ_QUERY_EA_STRING;
            break;
        case IRP_MJ_SET_EA:
            irpMajorString = IRP_MJ_SET_EA_STRING;
            break;
        case IRP_MJ_FLUSH_BUFFERS:
            irpMajorString = IRP_MJ_FLUSH_BUFFERS_STRING;
            break;
        case IRP_MJ_QUERY_VOLUME_INFORMATION:
            irpMajorString = IRP_MJ_QUERY_VOLUME_INFORMATION_STRING;
            break;
        case IRP_MJ_SET_VOLUME_INFORMATION:
            irpMajorString = IRP_MJ_SET_VOLUME_INFORMATION_STRING;
            break;
        case IRP_MJ_DIRECTORY_CONTROL:
            irpMajorString = IRP_MJ_DIRECTORY_CONTROL_STRING;
            switch (MinorCode) {
                case IRP_MN_QUERY_DIRECTORY:
                    irpMinorString = IRP_MN_QUERY_DIRECTORY_STRING;
                    break;
                case IRP_MN_NOTIFY_CHANGE_DIRECTORY:
                    irpMinorString = IRP_MN_NOTIFY_CHANGE_DIRECTORY_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_FILE_SYSTEM_CONTROL:
            irpMajorString = IRP_MJ_FILE_SYSTEM_CONTROL_STRING;
            switch (MinorCode) {
                case IRP_MN_USER_FS_REQUEST:
                    irpMinorString = IRP_MN_USER_FS_REQUEST_STRING;
                    break;
                case IRP_MN_MOUNT_VOLUME:
                    irpMinorString = IRP_MN_MOUNT_VOLUME_STRING;
                    break;
                case IRP_MN_VERIFY_VOLUME:
                    irpMinorString = IRP_MN_VERIFY_VOLUME_STRING;
                    break;
                case IRP_MN_LOAD_FILE_SYSTEM:
                    irpMinorString = IRP_MN_LOAD_FILE_SYSTEM_STRING;
                    break;
                case IRP_MN_TRACK_LINK:
                    irpMinorString = IRP_MN_TRACK_LINK_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_DEVICE_CONTROL:
            irpMajorString = IRP_MJ_DEVICE_CONTROL_STRING;
            switch (MinorCode) {
                case IRP_MN_SCSI_CLASS:
                    irpMinorString = IRP_MN_SCSI_CLASS_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_INTERNAL_DEVICE_CONTROL:
            irpMajorString = IRP_MJ_INTERNAL_DEVICE_CONTROL_STRING;
            break;
        case IRP_MJ_SHUTDOWN:
            irpMajorString = IRP_MJ_SHUTDOWN_STRING;
            break;
        case IRP_MJ_LOCK_CONTROL:
            irpMajorString = IRP_MJ_LOCK_CONTROL_STRING;
            switch (MinorCode) {
                case IRP_MN_LOCK:
                    irpMinorString = IRP_MN_LOCK_STRING;
                    break;
                case IRP_MN_UNLOCK_SINGLE:
                    irpMinorString = IRP_MN_UNLOCK_SINGLE_STRING;
                    break;
                case IRP_MN_UNLOCK_ALL:
                    irpMinorString = IRP_MN_UNLOCK_ALL_STRING;
                    break;
                case IRP_MN_UNLOCK_ALL_BY_KEY:
                    irpMinorString = IRP_MN_UNLOCK_ALL_BY_KEY_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_CLEANUP:
            irpMajorString = IRP_MJ_CLEANUP_STRING;
            break;
        case IRP_MJ_CREATE_MAILSLOT:
            irpMajorString = IRP_MJ_CREATE_MAILSLOT_STRING;
            break;
        case IRP_MJ_QUERY_SECURITY:
            irpMajorString = IRP_MJ_QUERY_SECURITY_STRING;
            break;
        case IRP_MJ_SET_SECURITY:
            irpMajorString = IRP_MJ_SET_SECURITY_STRING;
            break;
        case IRP_MJ_POWER:
            irpMajorString = IRP_MJ_POWER_STRING;
            switch (MinorCode) {
                case IRP_MN_WAIT_WAKE:
                    irpMinorString = IRP_MN_WAIT_WAKE_STRING;
                    break;
                case IRP_MN_POWER_SEQUENCE:
                    irpMinorString = IRP_MN_POWER_SEQUENCE_STRING;
                    break;
                case IRP_MN_SET_POWER:
                    irpMinorString = IRP_MN_SET_POWER_STRING;
                    break;
                case IRP_MN_QUERY_POWER:
                    irpMinorString = IRP_MN_QUERY_POWER_STRING;
                    break;
                default :
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_SYSTEM_CONTROL:
            irpMajorString = IRP_MJ_SYSTEM_CONTROL_STRING;
            switch (MinorCode) {
                case IRP_MN_QUERY_ALL_DATA:
                    irpMinorString = IRP_MN_QUERY_ALL_DATA_STRING;
                    break;
                case IRP_MN_QUERY_SINGLE_INSTANCE:
                    irpMinorString = IRP_MN_QUERY_SINGLE_INSTANCE_STRING;
                    break;
                case IRP_MN_CHANGE_SINGLE_INSTANCE:
                    irpMinorString = IRP_MN_CHANGE_SINGLE_INSTANCE_STRING;
                    break;
                case IRP_MN_CHANGE_SINGLE_ITEM:
                    irpMinorString = IRP_MN_CHANGE_SINGLE_ITEM_STRING;
                    break;
                case IRP_MN_ENABLE_EVENTS:
                    irpMinorString = IRP_MN_ENABLE_EVENTS_STRING;
                    break;
                case IRP_MN_DISABLE_EVENTS:
                    irpMinorString = IRP_MN_DISABLE_EVENTS_STRING;
                    break;
                case IRP_MN_ENABLE_COLLECTION:
                    irpMinorString = IRP_MN_ENABLE_COLLECTION_STRING;
                    break;
                case IRP_MN_DISABLE_COLLECTION:
                    irpMinorString = IRP_MN_DISABLE_COLLECTION_STRING;
                    break;
                case IRP_MN_REGINFO:
                    irpMinorString = IRP_MN_REGINFO_STRING;
                    break;
                case IRP_MN_EXECUTE_METHOD:
                    irpMinorString = IRP_MN_EXECUTE_METHOD_STRING;
                    break;
                default :
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;

        case IRP_MJ_DEVICE_CHANGE:
            irpMajorString = IRP_MJ_DEVICE_CHANGE_STRING;
            break;
        case IRP_MJ_QUERY_QUOTA:
            irpMajorString = IRP_MJ_QUERY_QUOTA_STRING;
            break;
        case IRP_MJ_SET_QUOTA:
            irpMajorString = IRP_MJ_SET_QUOTA_STRING;
            break;
        case IRP_MJ_PNP:
            irpMajorString = IRP_MJ_PNP_STRING;
            switch (MinorCode) {
                case IRP_MN_START_DEVICE:
                    irpMinorString = IRP_MN_START_DEVICE_STRING;
                    break;
                case IRP_MN_QUERY_REMOVE_DEVICE:
                    irpMinorString = IRP_MN_QUERY_REMOVE_DEVICE_STRING;
                    break;
                case IRP_MN_REMOVE_DEVICE:
                    irpMinorString = IRP_MN_REMOVE_DEVICE_STRING;
                    break;
                case IRP_MN_CANCEL_REMOVE_DEVICE:
                    irpMinorString = IRP_MN_CANCEL_REMOVE_DEVICE_STRING;
                    break;
                case IRP_MN_STOP_DEVICE:
                    irpMinorString = IRP_MN_STOP_DEVICE_STRING;
                    break;
                case IRP_MN_QUERY_STOP_DEVICE:
                    irpMinorString = IRP_MN_QUERY_STOP_DEVICE_STRING;
                    break;
                case IRP_MN_CANCEL_STOP_DEVICE:
                    irpMinorString = IRP_MN_CANCEL_STOP_DEVICE_STRING;
                    break;
                case IRP_MN_QUERY_DEVICE_RELATIONS:
                    irpMinorString = IRP_MN_QUERY_DEVICE_RELATIONS_STRING;
                    break;
                case IRP_MN_QUERY_INTERFACE:
                    irpMinorString = IRP_MN_QUERY_INTERFACE_STRING;
                    break;
                case IRP_MN_QUERY_CAPABILITIES:
                    irpMinorString = IRP_MN_QUERY_CAPABILITIES_STRING;
                    break;
                case IRP_MN_QUERY_RESOURCES:
                    irpMinorString = IRP_MN_QUERY_RESOURCES_STRING;
                    break;
                case IRP_MN_QUERY_RESOURCE_REQUIREMENTS:
                    irpMinorString = IRP_MN_QUERY_RESOURCE_REQUIREMENTS_STRING;
                    break;
                case IRP_MN_QUERY_DEVICE_TEXT:
                    irpMinorString = IRP_MN_QUERY_DEVICE_TEXT_STRING;
                    break;
                case IRP_MN_FILTER_RESOURCE_REQUIREMENTS:
                    irpMinorString = IRP_MN_FILTER_RESOURCE_REQUIREMENTS_STRING;
                    break;
                case IRP_MN_READ_CONFIG:
                    irpMinorString = IRP_MN_READ_CONFIG_STRING;
                    break;
                case IRP_MN_WRITE_CONFIG:
                    irpMinorString = IRP_MN_WRITE_CONFIG_STRING;
                    break;
                case IRP_MN_EJECT:
                    irpMinorString = IRP_MN_EJECT_STRING;
                    break;
                case IRP_MN_SET_LOCK:
                    irpMinorString = IRP_MN_SET_LOCK_STRING;
                    break;
                case IRP_MN_QUERY_ID:
                    irpMinorString = IRP_MN_QUERY_ID_STRING;
                    break;
                case IRP_MN_QUERY_PNP_DEVICE_STATE:
                    irpMinorString = IRP_MN_QUERY_PNP_DEVICE_STATE_STRING;
                    break;
                case IRP_MN_QUERY_BUS_INFORMATION:
                    irpMinorString = IRP_MN_QUERY_BUS_INFORMATION_STRING;
                    break;
                case IRP_MN_DEVICE_USAGE_NOTIFICATION:
                    irpMinorString = IRP_MN_DEVICE_USAGE_NOTIFICATION_STRING;
                    break;
                case IRP_MN_SURPRISE_REMOVAL:
                    irpMinorString = IRP_MN_SURPRISE_REMOVAL_STRING;
                    break;
                case IRP_MN_QUERY_LEGACY_BUS_INFORMATION:
                    irpMinorString = IRP_MN_QUERY_LEGACY_BUS_INFORMATION_STRING;
                    break;
                default :
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp minor code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;


        case IRP_MJ_ACQUIRE_FOR_SECTION_SYNCHRONIZATION:
            irpMajorString = IRP_MJ_ACQUIRE_FOR_SECTION_SYNCHRONIZATION_STRING;
            break;

        case IRP_MJ_RELEASE_FOR_SECTION_SYNCHRONIZATION:
            irpMajorString = IRP_MJ_RELEASE_FOR_SECTION_SYNCHRONIZATION_STRING;
            break;

        case IRP_MJ_ACQUIRE_FOR_MOD_WRITE:
            irpMajorString = IRP_MJ_ACQUIRE_FOR_MOD_WRITE_STRING;
            break;

        case IRP_MJ_RELEASE_FOR_MOD_WRITE:
            irpMajorString = IRP_MJ_RELEASE_FOR_MOD_WRITE_STRING;
            break;

        case IRP_MJ_ACQUIRE_FOR_CC_FLUSH:
            irpMajorString = IRP_MJ_ACQUIRE_FOR_CC_FLUSH_STRING;
            break;

        case IRP_MJ_RELEASE_FOR_CC_FLUSH:
            irpMajorString = IRP_MJ_RELEASE_FOR_CC_FLUSH_STRING;
            break;

        case IRP_MJ_NOTIFY_STREAM_FO_CREATION:
            irpMajorString = IRP_MJ_NOTIFY_STREAM_FO_CREATION_STRING;
            break;



        case IRP_MJ_FAST_IO_CHECK_IF_POSSIBLE:
            irpMajorString = IRP_MJ_FAST_IO_CHECK_IF_POSSIBLE_STRING;
            break;

        case IRP_MJ_NETWORK_QUERY_OPEN:
            irpMajorString = IRP_MJ_NETWORK_QUERY_OPEN_STRING;
            break;

        case IRP_MJ_MDL_READ:
            irpMajorString = IRP_MJ_MDL_READ_STRING;
            break;

        case IRP_MJ_MDL_READ_COMPLETE:
            irpMajorString = IRP_MJ_MDL_READ_COMPLETE_STRING;
            break;

        case IRP_MJ_PREPARE_MDL_WRITE:
            irpMajorString = IRP_MJ_PREPARE_MDL_WRITE_STRING;
            break;

        case IRP_MJ_MDL_WRITE_COMPLETE:
            irpMajorString = IRP_MJ_MDL_WRITE_COMPLETE_STRING;
            break;

        case IRP_MJ_VOLUME_MOUNT:
            irpMajorString = IRP_MJ_VOLUME_MOUNT_STRING;
            break;

        case IRP_MJ_VOLUME_DISMOUNT:
            irpMajorString = IRP_MJ_VOLUME_DISMOUNT_STRING;
            break;

        case IRP_MJ_TRANSACTION_NOTIFY:
            irpMajorString = IRP_MJ_TRANSACTION_NOTIFY_STRING;
            switch (MinorCode) {
                case 0:
                    irpMinorString = TRANSACTION_BEGIN;
                    break;
                case TRANSACTION_NOTIFY_PREPREPARE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_PREPREPARE_STRING;
                    break;
                case TRANSACTION_NOTIFY_PREPARE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_PREPARE_STRING;
                    break;
                case TRANSACTION_NOTIFY_COMMIT_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_COMMIT_STRING;
                    break;
                case TRANSACTION_NOTIFY_COMMIT_FINALIZE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_COMMIT_FINALIZE_STRING;
                    break;
                case TRANSACTION_NOTIFY_ROLLBACK_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_ROLLBACK_STRING;
                    break;
                case TRANSACTION_NOTIFY_PREPREPARE_COMPLETE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_PREPREPARE_COMPLETE_STRING;
                    break;
                case TRANSACTION_NOTIFY_PREPARE_COMPLETE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_COMMIT_COMPLETE_STRING;
                    break;
                case TRANSACTION_NOTIFY_ROLLBACK_COMPLETE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_ROLLBACK_COMPLETE_STRING;
                    break;
                case TRANSACTION_NOTIFY_RECOVER_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_RECOVER_STRING;
                    break;
                case TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT_STRING;
                    break;
                case TRANSACTION_NOTIFY_DELEGATE_COMMIT_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_DELEGATE_COMMIT_STRING;
                    break;
                case TRANSACTION_NOTIFY_RECOVER_QUERY_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_RECOVER_QUERY_STRING;
                    break;
                case TRANSACTION_NOTIFY_ENLIST_PREPREPARE_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_ENLIST_PREPREPARE_STRING;
                    break;
                case TRANSACTION_NOTIFY_LAST_RECOVER_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_LAST_RECOVER_STRING;
                    break;
                case TRANSACTION_NOTIFY_INDOUBT_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_INDOUBT_STRING;
                    break;
                case TRANSACTION_NOTIFY_PROPAGATE_PULL_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_PROPAGATE_PULL_STRING;
                    break;
                case TRANSACTION_NOTIFY_PROPAGATE_PUSH_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_PROPAGATE_PUSH_STRING;
                    break;
                case TRANSACTION_NOTIFY_MARSHAL_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_MARSHAL_STRING;
                    break;
                case TRANSACTION_NOTIFY_ENLIST_MASK_CODE:
                    irpMinorString = TRANSACTION_NOTIFY_ENLIST_MASK_STRING;
                    break;
                default:
                    sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Transaction notication code (%u)",MinorCode);
                    irpMinorString = errorBuf;
            }
            break;


        default:
            sprintf_s(errorBuf,sizeof(errorBuf),"Unknown Irp major function (%d)",MajorCode);
            irpMajorString = errorBuf;
            break;
    }

    *MajorStringOut = irpMajorString;
    *MinorStringOut = irpMinorString;
}


ULONG
FormatSystemTime(
    _In_ SYSTEMTIME *SystemTime,
    _Out_writes_bytes_(BufferLength) CHAR *Buffer,
    _In_ ULONG BufferLength
    )
/*++
Routine Description:

    Formats the values in a SystemTime struct into the buffer
    passed in.  The resulting string is NULL terminated.  The format
    for the time is:
        hours:minutes:seconds:milliseconds

Arguments:

    SystemTime - the struct to format
    Buffer - the buffer to place the formatted time in
    BufferLength - the size of the buffer

Return Value:

    The length of the string returned in Buffer.

--*/
{
    ULONG returnLength = 0;

    if (BufferLength < TIME_BUFFER_LENGTH) {

        //
        // Buffer is too short so exit
        //

        return 0;
    }

    returnLength = sprintf_s( Buffer,
                            BufferLength,
                            "%02d:%02d:%02d:%03d",
                            SystemTime->wHour,
                            SystemTime->wMinute,
                            SystemTime->wSecond,
                            SystemTime->wMilliseconds );

    return returnLength;
}

// ======================================== MY ADDED FUNCTIONSCHANGES ========================================

void 
NtStatusToString(
    ULONG status, 
    char* buffer, 
    size_t bufferSize
) 
{
    DWORD result = FormatMessageA(
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        status,
        0,
        buffer,
        (DWORD)bufferSize,
        NULL
    );

    if (result == 0) {
        snprintf(buffer, bufferSize, "Unknown NTSTATUS: 0x%08X", status);
    }
}

void
WriteToLogAnsi(
    const char* message
    , ...
)
{
    //Proceed to format message.
    char buffer[1024];

    va_list args;
    va_start(args, message);
    vsnprintf(buffer, sizeof(buffer), message, args);
    va_end(args);

    FILE* logFile;
    fopen_s(&logFile, USER_LOG_FILE, "a+");
    if (logFile) {
        SYSTEMTIME time;
        GetLocalTime(&time);
        fprintf(logFile, "[%02d:%02d:%02d] %s\n",
            time.wHour, time.wMinute, time.wSecond, buffer);
        fclose(logFile);
    }
}

// Function to check if a file exists
int
FileExists(
    const char* filepath
)
{
    DWORD attrib = GetFileAttributesA(filepath);
    return (attrib != INVALID_FILE_ATTRIBUTES && !(attrib & FILE_ATTRIBUTE_DIRECTORY));
}

//For initialising database from create.sql file
char* 
LoadEmbeddedSQL(
    DWORD* outSize
) 
{
    HMODULE hModule = GetModuleHandle(NULL);
    HRSRC hRes = FindResource(hModule, L"CREATE_SQL", RT_RCDATA);
    if (!hRes) return NULL;

    HGLOBAL hData = LoadResource(hModule, hRes);
    if (!hData) return NULL;

    DWORD size = SizeofResource(hModule, hRes);
    void* pData = LockResource(hData);
    if (!pData) return NULL;

    if (outSize) *outSize = size;
    return (char*)pData;
}

// Function to initialize the database
int
InitializeDatabase()
{
    sqlite3* db = NULL;
    char* errMsg = NULL;

    // Check if database file exists
    if (FileExists(DATABASE_FILE_LOCATION)) {
        //if it does, no need to go further
        return 1;
    }

    // Try to open/create the database
    if (sqlite3_open(DATABASE_FILE_LOCATION, &db) != SQLITE_OK) {
        WriteToLogAnsi("Failed to open database: %s\n", sqlite3_errmsg(db));
        return 0;
    }

    // Load embedded SQL from resource
    DWORD sqlSize = 0;
    char* sqlContent = LoadEmbeddedSQL(&sqlSize);
    if (!sqlContent || sqlSize == 0) {
        sqlite3_close(db);
        return 0;
    }

    // Initialize schema using embedded SQL
    WriteToLogAnsi("Database does not exist. Initializing...");
    int rc = sqlite3_exec(db, sqlContent, NULL, NULL, &errMsg);
    if (rc != SQLITE_OK) {
        WriteToLogAnsi("SQL error: %s\n", errMsg);
        sqlite3_free(errMsg);
        sqlite3_close(db);
        return 0;
    }
    WriteAlertToDatabase("Database creation and initialization!");

    WriteToLogAnsi("Database initialized.");
    sqlite3_close(db);
    return 1;
}

VOID
WriteAlertToDatabase(
    const char* message
    , ...
) {
    //Check whether database exists and initialized first
    int success = InitializeDatabase();
    if (!success) return;

    //Assume database doesn't exist yet, and start setting it up.
    sqlite3* db = NULL;
    sqlite3_stmt* stmt = NULL;

    int rc = sqlite3_open(DATABASE_FILE_LOCATION, &db);
    if (rc != SQLITE_OK) return;

    // Set insert statement
    char* sql = "INSERT INTO Alerts (Timestamp, AlertMessage) VALUES (?, ?);";;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        sqlite3_close(db);
        return;
    }

    sqlite3_bind_int64(stmt, 0, (sqlite3_int64)time(NULL)); // 100ns ticks

    //Proceed to format message.
    char buffer[1024];

    va_list args;
    va_start(args, message);
    vsnprintf(buffer, sizeof(buffer), message, args);
    va_end(args);

    sqlite3_bind_text(stmt, 1, buffer, -1, SQLITE_TRANSIENT);

    //Execute insert command
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        //if it fails?
        const char* errorMsg = sqlite3_errmsg(db);
        char logMessage[512];
        snprintf(logMessage, sizeof(logMessage), "SQLite insert failed on Alert: %s", errorMsg);
        WriteToLogAnsi(logMessage);
    }

    //Clean up
    sqlite3_finalize(stmt);
    sqlite3_close(db);
}

VOID
DatabaseDump(
    _In_ ULONG SequenceNumber,
    _In_ WCHAR CONST* Name,
    _In_ PRECORD_DATA RecordData
)
/*
Routine Desciption:

    Grabs all the data from the log records and writes them to database

Arguments:

    SequenceNumber - the sequence number for this log record
    Name - the name of the file that this Irp relates to
    RecordData - the Data record to print

Return Value:

    None.

*/
{
    //For storing sql query

    //Try to initialise Database first and return status
    int success = InitializeDatabase();
    if (!success) return; //

    //Start with assuming we have no database
    sqlite3* db = NULL;
    sqlite3_stmt* stmt = NULL;

    int rc = sqlite3_open(DATABASE_FILE_LOCATION, &db);
    if (rc != SQLITE_OK) return;

    //sqlite3_exec(db, "PRAGMA journal_mode=WAL;", 0, 0, 0);

    // Set insert statement
    char* sql = "INSERT INTO MinifilterLog (SeqNum, OprType, PreOpTime, PostOpTime, ProcessId, ProcessFilePath, ThreadId, MajorOp, MinorOp, IrpFlags, DeviceObj, FileObj, FileTransaction, OpStatus, Information, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, OpFileName, RequestorMode, RuleID, RuleAction) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        sqlite3_close(db);
        return;
    }

    //Set Sequence Number
    sqlite3_bind_int64(stmt, 1, (sqlite3_int64)SequenceNumber);

    // Type of Operation (OprType)
    const char* oprType = (RecordData->Flags & FLT_CALLBACK_DATA_IRP_OPERATION) ? "IRP" :
        (RecordData->Flags & FLT_CALLBACK_DATA_FAST_IO_OPERATION) ? "FIO" :
        (RecordData->Flags & FLT_CALLBACK_DATA_FS_FILTER_OPERATION) ? "FSF" : "ERR";
    sqlite3_bind_text(stmt, 2, oprType, -1, SQLITE_TRANSIENT);

    // Convert to Unix timestamp with microsecond precision
    INT64 preOpUnix = (RecordData->OriginatingTime.QuadPart - EPOCH_DIFF);
    sqlite3_bind_int64(stmt, 3, preOpUnix); // 100ns ticks

    // Convert to Unix timestamp with microsecond precision
    INT64 postOpUnix = (RecordData->CompletionTime.QuadPart - EPOCH_DIFF);
    sqlite3_bind_int64(stmt, 4, postOpUnix); // 100ns ticks

    //Set Process ID
    sqlite3_bind_int64(stmt, 5, (sqlite3_int64)RecordData->ProcessId);
    
    // Set Process File Path using ANSI version (QueryFullProcessImageNameA)
    char processPath[MAX_PATH];
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, (DWORD)(ULONG_PTR)RecordData->ProcessId);

    if (hProcess != NULL) {
        DWORD size = MAX_PATH;
        if (QueryFullProcessImageNameA(hProcess, 0, processPath, &size)) {
            sqlite3_bind_text(stmt, 6, processPath, -1, SQLITE_TRANSIENT);
        }
        else {
            sqlite3_bind_text(stmt, 6, "<NO PATH>", -1, SQLITE_TRANSIENT);
        }
        CloseHandle(hProcess);
    }
    else {
        sqlite3_bind_text(stmt, 6, "<NO PROCESS>", -1, SQLITE_TRANSIENT);
    }

    //Set Thread ID
    sqlite3_bind_int64(stmt, 7, (sqlite3_int64)RecordData->ThreadId);

    //Set Major and Minor Operation
    const CHAR* majorStrBuf = NULL;
    const CHAR* minorStrBuf = NULL;

    PrintIrpCode(
        RecordData->CallbackMajorId,
        RecordData->CallbackMinorId,
        &majorStrBuf,
        &minorStrBuf
    );

    sqlite3_bind_text(stmt, 8, majorStrBuf, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 9, minorStrBuf, -1, SQLITE_TRANSIENT);

    //Set IRP (I/O Request Packet) Flags
    // Interpret set IrpFlags (it acts as bit mask, so we want to translate so more human readable)
    char flagStr[9] = "--------";

    if (RecordData->IrpFlags & IRP_NOCACHE) flagStr[0] = 'N';
    if (RecordData->IrpFlags & IRP_PAGING_IO) flagStr[1] = 'P';
    if (RecordData->IrpFlags & IRP_SYNCHRONOUS_API) flagStr[2] = 'S';

    // This Irp Flag has overloaded meaning (multiple definitions for same value / contedxt specific)
    if (RecordData->IrpFlags & 0x40) {
        // if its a read or write operation
        if (RecordData->CallbackMajorId == IRP_MJ_READ || RecordData->CallbackMajorId == IRP_MJ_WRITE) {
            // Interpret as input vs output
            flagStr[3] = (RecordData->IrpFlags & IRP_INPUT_OPERATION) ? 'I' : 'O';
        }
        else if (RecordData->IrpFlags & IRP_PAGING_IO) {
            // Interpret as synchronous paging
            flagStr[3] = 'Y';
        }
        else {
            // Not sure, just log the bit was set - shouldn't really happen but just in case
            flagStr[3] = '?';
        }
    }
    else {
        //If the flag is not there, then give empty
        flagStr[3] = '-';
    }

    if (RecordData->IrpFlags & IRP_CREATE_OPERATION) flagStr[4] = 'C';
    if (RecordData->IrpFlags & IRP_READ_OPERATION) flagStr[5] = 'R';
    if (RecordData->IrpFlags & IRP_WRITE_OPERATION) flagStr[6] = 'W';
    if (RecordData->IrpFlags & IRP_CLOSE_OPERATION) flagStr[7] = 'X';
    sqlite3_bind_text(stmt, 10, flagStr, -1, SQLITE_TRANSIENT);

    char ptrBuf[32];
    //Get file type information and set it. These are all Handles
    //      DeviceObject      - Represents the device or volume involved in the operation.
    sprintf_s(ptrBuf, sizeof(ptrBuf), "%p", (void*)RecordData->DeviceObject);
    sqlite3_bind_text(stmt, 11, ptrBuf, -1, SQLITE_TRANSIENT);
    //      FileObject        - Represents the file, directory, or stream that the IRP is acting on.
    sprintf_s(ptrBuf, sizeof(ptrBuf), "%p", (void*)RecordData->FileObject);
    sqlite3_bind_text(stmt, 12, ptrBuf, -1, SQLITE_TRANSIENT);
    //      Transaction       - Used for Transactional NTFS (TxF) operations. - Rare operation
    sprintf_s(ptrBuf, sizeof(ptrBuf), "%p", (void*)RecordData->Transaction);
    sqlite3_bind_text(stmt, 13, ptrBuf, -1, SQLITE_TRANSIENT);

    //Set NTSTATUS of the operation, translated into more human readable format
    //          ======= CHANGE TO TRANSLATE FROM DATABASE TABLE FOREIGN KEY INSTEAD
    char statusStr[256];
    NtStatusToString(RecordData->Status, statusStr, sizeof(statusStr));
    sqlite3_bind_text(stmt, 14, statusStr, -1, SQLITE_TRANSIENT);

    sprintf_s(ptrBuf, sizeof(ptrBuf), "%p", (void*)RecordData->Information);
    sqlite3_bind_text(stmt, 15, ptrBuf, -1, SQLITE_TRANSIENT);

    //Set Arguments for the operations
    sqlite3_bind_int(stmt, 16, *(int*)&RecordData->Arg1);
    sqlite3_bind_int(stmt, 17, *(int*)&RecordData->Arg2);
    sqlite3_bind_int(stmt, 18, *(int*)&RecordData->Arg3);
    sqlite3_bind_int(stmt, 19, *(int*)&RecordData->Arg4);
    sqlite3_bind_int(stmt, 20, *(int*)&RecordData->Arg5);

    /*sprintf_s(ptrBuf, sizeof(ptrBuf), "%I64d", RecordData->Arg6.QuadPart);
    sqlite3_bind_text(stmt, 21, ptrBuf, -1, SQLITE_TRANSIENT);*/

    sqlite3_bind_int64(stmt, 21, *(sqlite3_int64*)&RecordData->Arg6.QuadPart);

    //Set the file name associated with the operation
    sqlite3_bind_text16(stmt, 22, Name, -1, SQLITE_TRANSIENT);

    //Set Requestor mode, whether operation from kernel or user
    sqlite3_bind_text(stmt, 23, RecordData->RequestorMode ? "Kernel" : "User", -1, SQLITE_TRANSIENT);
    //Set what rule then blocked the operation if it was (from the block list)
    sqlite3_bind_int(stmt, 24, RecordData->BlockingRuleID);

    sqlite3_bind_int(stmt, 25, 0);

    //Execute insert command
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        //if it fails?
        const char* errorMsg = sqlite3_errmsg(db);
        char logMessage[512];
        snprintf(logMessage, sizeof(logMessage), "SQLite insert failed on Kernel Operation: %s", errorMsg);
        WriteToLogAnsi(logMessage);
    }

    //Clean up
    sqlite3_finalize(stmt);
    sqlite3_close(db);
}