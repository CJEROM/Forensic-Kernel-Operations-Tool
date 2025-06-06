-- To initialize into db file run the command: .read create.sql
-- DROP TABLE IF EXISTS MinifilterLog;
CREATE TABLE IF NOT EXISTS MinifilterLog (
    LogID INTEGER PRIMARY KEY AUTOINCREMENT,-- A unique identifier for each log entry.
    SeqNum INTEGER,                 --Sequence Number (SeqNum)
    OprType TEXT,                -- Operation Type (Opr) - Identifies the operation type: IRP (I/O Request Packet), FIO (Fast I/O), FSF (File System Filter Operation), ERR (Error)
    PreOpTime DATETIME,                 -- Time when the operation started.
    PostOpTime DATETIME,                -- Time when the operation completed.
    ProcessId INTEGER,                      -- The process ID that triggered the operation.
    ProcessFilePath TEXT,
    ThreadId INTEGER,                       -- The thread ID that triggered the operation.
    MajorOp TEXT,                -- The high-level I/O operation (e.g., Create, Read, Write).
    MinorOp TEXT,                -- A more specific sub-operation within the major category.
    IrpFlags TEXT,               -- Flags describing request characteristics (e.g., N for NoCache, P for Paging I/O, S for Synchronous).
    DeviceObj TEXT,                  -- Device object pointer.
    FileObj TEXT,                    -- File object pointer.
    FileTransaction TEXT,            -- Transaction pointer (if applicable).
    OpStatus TEXT,                       -- Return status and information about the operation.
    Information TEXT,                -- 
    Arg1 INTEGER,                       -- Operation-specific parameters (e.g., buffer addresses, offsets).
    Arg2 INTEGER,                       -- 
    Arg3 INTEGER,                       -- 
    Arg4 INTEGER,                       -- 
    Arg5 INTEGER,                       -- 
    Arg6 TEXT,                        -- 
    OpFileName TEXT,           -- The name of the file associated with the operation.
    RequestorMode TEXT,
    RuleID INTEGER,
    RuleAction INTEGER,
    FOREIGN KEY (MajorOp) REFERENCES MajorIRPCodes(MajorIRPCodeID),
    FOREIGN KEY (MinorOp) REFERENCES MinorIRPCodes(MinorIRPCodeID),
    FOREIGN KEY (OprType) REFERENCES OperationTypes(OperationTypeID),
    FOREIGN KEY (IrpFlags) REFERENCES IRPFlags(IRPFlagID),
    FOREIGN KEY (RuleID) REFERENCES Rules(RuleID)
);

-- DROP TABLE IF EXISTS Alerts;
CREATE TABLE IF NOT EXISTS Alerts (
    AlertID INTEGER PRIMARY KEY AUTOINCREMENT,
    Timestamp DATETIME NOT NULL,
    AlertMessage TEXT                                       -- Human-readable explanation
);

-- Idea is to store the definitions for all of the data here
-- DROP TABLE IF EXISTS Definitions;
CREATE TABLE IF NOT EXISTS ColumnDescriptions (
    ColumnID INT PRIMARY KEY,
    ColumnName TEXT NOT NULL,
    ColumnLongName TEXT NOT NULL,
    ColumnDescritpion TEXT NOT NULL
);
INSERT INTO ColumnDescriptions (ColumnID, ColumnName, ColumnLongName, ColumnDescritpion)
VALUES 
    (0, "LogID", "Log ID", "A unique identifier for each log entry."),
    (1, "SeqNum", "Sequence Number", "Sequence Number (SeqNum)"),
    (2, "OprType", "Operation Type", "Operation Type (Opr) - Identifies the operation type: IRP (I/O Request Packet), FIO (Fast I/O), FSF (File System Filter Operation), ERR (Error)"),
    (3, "PreOpTime", "Pre Operation Start Time", "Time when the operation started."),
    (4, "PostOpTime", "Post Operation Completion Time", "Time when the operation completed."),
    (5, "ProcessId", "ProcessID", "The process ID that triggered the operation."),
    (6, "ProcessFilePath", "Process File Path", ""),
    (7, "ThreadId", "Thread ID", "The thread ID that triggered the operation."),
    (8, "MajorOp", "IRP Major Operation", "The high-level I/O operation (e.g., Create, Read, Write)."),
    (9, "MinorOp", "IRP Minor Operation", "A more specific sub-operation within the major category."),
    (10, "IrpFlags", "Irp Flags", "Flags describing request characteristics (e.g., N for NoCache, P for Paging I/O, S for Synchronous)."),
    (11, "DeviceObj", "Device Object", "Device object pointer."),
    (12, "FileObj", "File Object", "File object pointer."),
    (13, "FileTransaction", "File Transaction", "Transaction pointer (if applicable)."),
    (14, "OpStatus", "Operation Status", "Return status and information about the operation."),
    (15, "Information", "Information", ""),
    (16, "Arg1", "Argument 1", "Operation-specific parameter 1 (e.g., buffer addresses, offsets)."),
    (17, "Arg2", "Argument 2", "Operation-specific parameter 2"),
    (18, "Arg3", "Argument 3", "Operation-specific parameter 3"),
    (19, "Arg4", "Argument 4", "Operation-specific parameter 4"),
    (20, "Arg5", "Argument 5", "Operation-specific parameter 5"),
    (21, "Arg6", "Argument 6", "Operation-specific parameter 6"),
    (22, "OpFileName", "Operation File Name", "The name of the file associated with the operation."),
    (23, "RequestorMode", "Requestor Mode", ""),
    (24, "RuleID", "Rule ID", ""),
    (25, "RuleAction", "Rule Action", "");


-- DROP TABLE IF EXISTS OperationTypes;
CREATE TABLE IF NOT EXISTS OperationTypes (
    OperationTypeID INTEGER PRIMARY KEY AUTOINCREMENT,
    OperationType TEXT NOT NULL,
    OperationTypeName TEXT NOT NULL,
    Descritpion TEXT NOT NULL
);
INSERT INTO OperationTypes (OperationType, OperationTypeName, Descritpion) 
VALUES 
    ("FIO", "Fast I/O", "Fast I/O operations handled outside of normal IRP processing."),
    ("FSF", "File System Filter", "File System Filter-specific operations, not part of standard IRP/MJ codes."),
    ("IRP", "I/O Request Packet", "Standard I/O Request Packet operations used in driver communication.");


-- Create a new table to store major IRP (I/O Request Packet) codes
-- DROP TABLE IF EXISTS MajorIRPCodes;
CREATE TABLE IF NOT EXISTS MajorIRPCodes (
    MajorIRPCodeID INTEGER PRIMARY KEY,     -- Unique ID for each IRP code
    MajorIRPCode TEXT NOT NULL,         -- Name of the IRP operation
    Description TEXT NOT NULL,          -- What the Major IRP Code is for
    Link TEXT,
    ArgumentsLink TEXT,
);
-- Insert predefined list of Major IRP codes and their corresponding IDs
-- These codes represent different types of I/O operations handled by Windows drivers
INSERT INTO MajorIRPCodes (MajorIRPCodeID, MajorIRPCode, Description, Link, ArgumentsLink) 
VALUES
    (0, 'IRP_MJ_CREATE', "Create/open a file or device", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-create", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-create"),    
    (1, 'IRP_MJ_CREATE_NAMED_PIPE', "Create a named pipe", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-create-named-pipe", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-create-named-pipe"),     
    (2, 'IRP_MJ_CLOSE', "Close a handle to a file or device", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-close", NULL),         
    (3, 'IRP_MJ_READ', "Read data from a file or device", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-read", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-read"),           
    (4, 'IRP_MJ_WRITE', "Write data to a file or device", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-write", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-write"),            
    (5, 'IRP_MJ_QUERY_INFORMATION', "Query file/device metadata", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-query-information", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-information"),    
    (6, 'IRP_MJ_SET_INFORMATION', "Set file/device metadata", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-set-information", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-set-information"),      
    (7, 'IRP_MJ_QUERY_EA', "Query extended attributes", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-query-ea", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-ea"),            
    (8, 'IRP_MJ_SET_EA', "Set extended attributes", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-set-ea", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-set-ea"),           
    (9, 'IRP_MJ_FLUSH_BUFFERS', "Flush buffered data to disk", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-flush-buffers", NULL),      
    (10, 'IRP_MJ_QUERY_VOLUME_INFORMATION', "Get volume info (e.g., label, size)", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-query-volume-information", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-volume-information"),
    (11, 'IRP_MJ_SET_VOLUME_INFORMATION', "Set volume information", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-set-volume-information", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-set-volume-information"), 
    (12, 'IRP_MJ_DIRECTORY_CONTROL', "Handle directory-related operations", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-directory-control", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-directory-control"),  
    (13, 'IRP_MJ_FILE_SYSTEM_CONTROL', "Filesystem-specific operations", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-file-system-control", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-file-system-control"),   
    (14, 'IRP_MJ_DEVICE_CONTROL', "Device-specific I/O control codes (IOCTL)", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-device-control", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-device-control-and-irp-mj-internal-device-co"),   
    (15, 'IRP_MJ_INTERNAL_DEVICE_CONTROL', "Internal I/O controls (kernel mode only)", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-internal-device-control", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-device-control-and-irp-mj-internal-device-co"), 
    (16, 'IRP_MJ_SHUTDOWN', "Prepare device for system shutdown", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-shutdown", NULL),        
    (17, 'IRP_MJ_LOCK_CONTROL', "File locking/unlocking operations", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-lock-control", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-lock-control"),      
    (18, 'IRP_MJ_CLEANUP', "Cleanup operations before handle closure", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-cleanup", NULL),         
    (19, 'IRP_MJ_CREATE_MAILSLOT', "Create a mailslot (message-based communication)", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-create-mailslot", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-create-mailslot"),   
    (20, 'IRP_MJ_QUERY_SECURITY', "Query file or device security descriptor", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-query-security", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-security"),    
    (21, 'IRP_MJ_SET_SECURITY', "Set file or device security descriptor", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-set-security", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-set-security"),       
    (22, 'IRP_MJ_POWER', "Power management (e.g., sleep/wake)", NULL, NULL),             
    (23, 'IRP_MJ_SYSTEM_CONTROL', "System control requests (e.g., WMI)", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-system-control"),  
    (24, 'IRP_MJ_DEVICE_CHANGE', "Device plug/unplug notifications", NULL, NULL),  
    (25, 'IRP_MJ_QUERY_QUOTA', "Query disk quota information", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-query-quota", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-quota"),  
    (26, 'IRP_MJ_SET_QUOTA', "Set disk quota limits", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-set-quota", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-set-quota"),   
    (27, 'IRP_MJ_PNP', "Plug and Play notifications", "https://learn.microsoft.com/en-us/previous-versions/windows/drivers/ifs/irp-mj-pnp", "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-pnp"), 
    (28, 'IRP_MJ_ACQUIRE_FOR_SECTION_SYNCHRONIZATION', "Prepare for memory-mapped file access (e.g., CreateFileMapping).", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-acquire-for-section-synchronization"),
    (29, 'IRP_MJ_RELEASE_FOR_SECTION_SYNCHRONIZATION', "Release locks from section synchronization.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-release-for-section-synchronization"),
    (30, 'IRP_MJ_ACQUIRE_FOR_MOD_WRITE', "Lock file for cache manager's modification write.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-acquire-for-mod-write"),
    (31, 'IRP_MJ_RELEASE_FOR_MOD_WRITE', "Release lock after mod write is done.", NULL, http://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-release-for-mod-write""),
    (32, 'IRP_MJ_ACQUIRE_FOR_CC_FLUSH', "Prepare to flush file data from cache.", NULL, NULL),
    (33, 'IRP_MJ_RELEASE_FOR_CC_FLUSH', "Release resources after cache flush.", NULL, NULL),
    (34, 'IRP_MJ_NOTIFY_STREAM_FO_CREATION', "Notifies when a stream file object is created.", NULL, NULL),
    (35, 'IRP_MJ_FAST_IO_CHECK_IF_POSSIBLE', "Check if fast I/O can be used.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-fast-io-check-if-possible"),
    (36, 'IRP_MJ_NETWORK_QUERY_OPEN', "Query file info over the network without opening.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-network-query-open"),
    (37, 'IRP_MJ_MDL_READ', "Map file data to memory for reading.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-mdl-read"),
    (38, 'IRP_MJ_MDL_READ_COMPLETE', "Finish MDL read and release resources.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-mdl-read-complete"),
    (39, 'IRP_MJ_PREPARE_MDL_WRITE', "Prepare memory for direct write access.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-prepare-mdl-write"),
    (40, 'IRP_MJ_MDL_WRITE_COMPLETE', "Complete MDL write and clean up.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-mdl-write-complete"),
    (41, 'IRP_MJ_VOLUME_MOUNT', "Sent when mounting a volume.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-volume-mount"),
    (42, 'IRP_MJ_VOLUME_DISMOUNT', "Sent when dismounting a volume.", NULL, NULL),
    (43, 'IRP_MJ_TRANSACTION_NOTIFY', "Notify filters of transaction events.", NULL, NULL),
    (44, 'IRP_MJ_QUERY_OPEN ', "Query file attributes on open.", NULL, "https://learn.microsoft.com/en-us/windows-hardware/drivers/ifs/flt-parameters-for-irp-mj-query-open");

-- Table for Minor IRP Codes
-- DROP TABLE IF EXISTS MinorIRPCodes;
CREATE TABLE IF NOT EXISTS MinorIRPCodes (
    MinorIRPCodeID INTEGER PRIMARY KEY AUTOINCREMENT, 
    MajorIRPCodeID INT NOT NULL,
    MinorIRPCode TEXT NOT NULL,
    Description TEXT NOT NULL,
    FOREIGN KEY (MajorIRPCodeID) REFERENCES MajorIRPCodes(MajorIRPCodeID)
);
INSERT INTO MinorIRPCodes (MajorIRPCodeID, MinorIRPCode, Description) 
VALUES
    --+ IRP_MJ_READ (8)
    (3, 'IRP_MN_NORMAL', 'Standard read operation'),
    (3, 'IRP_MN_DPC', 'Read completion in DPC context'),
    (3, 'IRP_MN_MDL', 'Read using a Memory Descriptor List'),
    (3, 'IRP_MN_COMPLETE', 'Read operation completed'),
    (3, 'IRP_MN_COMPRESSED', 'Read compressed data'),
    (3, 'IRP_MN_MDL_DPC', 'MDL read completion in DPC context'),
    (3, 'IRP_MN_COMPLETE_MDL', 'Complete MDL read'),
    (3, 'IRP_MN_COMPLETE_MDL_DPC', 'Complete MDL read in DPC'),
    --+ IRP_MJ_WRITE (8)
    (4, 'IRP_MN_NORMAL', 'Standard write operation'),
    (4, 'IRP_MN_DPC', 'Write completion in DPC context'),
    (4, 'IRP_MN_MDL', 'Write using a Memory Descriptor List'),
    (4, 'IRP_MN_COMPLETEG', 'Write operation completed'),
    (4, 'IRP_MN_COMPRESSED', 'Write compressed data'),
    (4, 'IRP_MN_MDL_DPC', 'MDL write completion in DPC context'),
    (4, 'IRP_MN_COMPLETE_MD', 'Complete MDL write'),
    (4, 'IRP_MN_COMPLETE_MDL_DPC', 'Complete MDL write in DPC'),
    --+ IRP_MJ_DIRECTORY_CONTROL (2)
    (12, 'IRP_MN_QUERY_DIRECTORY', 'Query directory contents'), 
    (12, 'IRP_MN_NOTIFY_CHANGE_DIRECTORY', 'Notify on directory changes'),
    --+ IRP_MJ_FILE_SYSTEM_CONTROL (5)
    (13, 'IRP_MN_USER_FS_REQUEST', 'User-mode FS control request'), 
    (13, 'IRP_MN_MOUNT_VOLUME', 'Mount a volume'), 
    (13, 'IRP_MN_VERIFY_VOLUME', 'Verify a volume'), 
    (13, 'IRP_MN_LOAD_FILE_SYSTEM', 'Load file system driver'), 
    (13, 'IRP_MN_TRACK_LINK', 'Track symbolic link creation'),
    --+ IRP_MJ_DEVICE_CONTROL (1)
    (14, 'IRP_MN_SCSI_CLASS', 'Class-specific SCSI command'),
    --+ IRP_MJ_LOCK_CONTROL (4)
    (17, 'IRP_MN_LOCK', 'Lock a file region'), 
    (17, 'IRP_MN_UNLOCK_SINGLE', 'Unlock a single region'), 
    (17, 'IRP_MN_UNLOCK_ALL', 'Unlock all regions by process'), 
    (17, 'IRP_MN_UNLOCK_ALL_BY_KEY', 'Unlock all by key'), 
    --+ IRP_MJ_POWER (4)
    (22, 'IRP_MN_WAIT_WAKE', 'Wake the device from low power'),
    (22, 'IRP_MN_POWER_SEQUENCE', 'Provide power sequence info'),
    (22, 'IRP_MN_SET_POWER', 'Set the power state'),
    (22, 'IRP_MN_QUERY_POWER', 'Query supported power states'),
    --+ IRP_MJ_SYSTEM_CONTROL (10)
    (23, 'IRP_MN_QUERY_ALL_DATA', 'Query all WMI data'), 
    (23, 'IRP_MN_QUERY_SINGLE_INSTANCE', 'Query specific WMI instance'),
    (23, 'IRP_MN_CHANGE_SINGLE_INSTANCE', 'Modify one WMI instance'),
    (23, 'IRP_MN_CHANGE_SINGLE_ITEM', 'Modify a WMI data item'),
    (23, 'IRP_MN_ENABLE_EVENTS', 'Enable WMI event notifications'),
    (23, 'IRP_MN_DISABLE_EVENTS', 'Disable WMI events'),
    (23, 'IRP_MN_ENABLE_COLLECTION', 'Enable data collection'),
    (23, 'IRP_MN_DISABLE_COLLECTION', 'Disable data collection'),
    (23, 'IRP_MN_REGINFO', 'Register WMI info'),
    (23, 'IRP_MN_EXECUTE_METHOD', 'Invoke a WMI method'),
    --+ IRP_MJ_PNP (24)
    (27, 'IRP_MN_START_DEVICE', 'Start a PnP device'),
    (27, 'IRP_MN_QUERY_REMOVE_DEVICE', 'Query if device can be removed'),
    (27, 'IRP_MN_REMOVE_DEVICE', 'Remove the device'),
    (27, 'IRP_MN_CANCEL_REMOVE_DEVICE', 'Cancel pending removal'),
    (27, 'IRP_MN_STOP_DEVICE', 'Stop the device'),
    (27, 'IRP_MN_QUERY_STOP_DEVICE', 'Query if device can be stopped'),
    (27, 'IRP_MN_CANCEL_STOP_DEVICE', 'Cancel device stop'),
    (27, 'IRP_MN_QUERY_DEVICE_RELATIONS', 'Query device relationships'),
    (27, 'IRP_MN_QUERY_INTERFACE', 'Query supported interfaces'),
    (27, 'IRP_MN_QUERY_CAPABILITIES', 'Query device capabilities'),
    (27, 'IRP_MN_QUERY_RESOURCES', 'Query assigned resources'),
    (27, 'IRP_MN_QUERY_RESOURCE_REQUIREMENTS', 'Query resource needs'),
    (27, 'IRP_MN_QUERY_DEVICE_TEXT', 'Query device description text'),
    (27, 'IRP_MN_FILTER_RESOURCE_REQUIREMENTS', 'Filter resource requests'),
    (27, 'IRP_MN_READ_CONFIG', 'Read device config space'),
    (27, 'IRP_MN_WRITE_CONFIG', 'Write to device config space'),
    (27, 'IRP_MN_EJECT', 'Eject the device'),
    (27, 'IRP_MN_SET_LOCK', 'Lock or unlock eject mechanism'),
    (27, 'IRP_MN_QUERY_ID', 'Query device identifiers'),
    (27, 'IRP_MN_QUERY_PNP_DEVICE_STATE', 'Query device state'),
    (27, 'IRP_MN_QUERY_BUS_INFORMATION', 'Query parent bus info'),
    (27, 'IRP_MN_DEVICE_USAGE_NOTIFICATION', 'Notify about device usage'),
    (27, 'IRP_MN_SURPRISE_REMOVAL', 'Device was unexpectedly removed'),
    (27, 'IRP_MN_QUERY_LEGACY_BUS_INFORMATION', 'Query legacy bus data'),
    --+ IRP_MJ_TRANSACTION_NOTIFY_STRING (20)
    (43 ,'TRANSACTION_BEGIN', 'Transaction start'),
    (43 ,'TRANSACTION_NOTIFY_PREPREPARE', 'Pre-prepare transaction'),
    (43 ,'TRANSACTION_NOTIFY_PREPARE', 'Prepare transaction'),
    (43 ,'TRANSACTION_NOTIFY_COMMIT', 'Commit transaction'),
    (43 ,'TRANSACTION_NOTIFY_COMMIT_FINALIZE', 'Finalize commit'),
    (43 ,'TRANSACTION_NOTIFY_ROLLBACK', 'Rollback transaction'),
    (43 ,'TRANSACTION_NOTIFY_PREPREPARE_COMPLETE', 'Pre-prepare done'),
    (43 ,'TRANSACTION_NOTIFY_COMMIT_COMPLETE', 'Commit done'),
    (43 ,'TRANSACTION_NOTIFY_ROLLBACK_COMPLETE', 'Rollback done'),
    (43 ,'TRANSACTION_NOTIFY_RECOVER', 'Recover transaction'),
    (43 ,'TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT', 'One-phase commit'),
    (43 ,'TRANSACTION_NOTIFY_DELEGATE_COMMIT', 'Delegate commit request'),
    (43 ,'TRANSACTION_NOTIFY_RECOVER_QUERY', 'Query recoverable transactions'),
    (43 ,'TRANSACTION_NOTIFY_ENLIST_PREPREPARE', 'Pre-prepare for enlistment'),
    (43 ,'TRANSACTION_NOTIFY_LAST_RECOVER', 'Last recovery notification'),
    (43 ,'TRANSACTION_NOTIFY_INDOUBT', 'Transaction indoubt'),
    (43 ,'TRANSACTION_NOTIFY_PROPAGATE_PULL', 'Pull transaction propagation'),
    (43 ,'TRANSACTION_NOTIFY_PROPAGATE_PUSH', 'Push transaction propagation'),
    (43 ,'TRANSACTION_NOTIFY_MARSHAL', 'Marshal transaction'),
    (43 ,'TRANSACTION_NOTIFY_ENLIST_MASK', 'Enlist mask notification');
    
-- Create the IRPFlags table
-- DROP TABLE IF EXISTS IRPFlags;
CREATE TABLE IF NOT EXISTS IRPFlags (
    IRPFlagID INTEGER PRIMARY KEY,
    IRPFlagName TEXT NOT NULL,
    Description TEXT NOT NULL
);
INSERT INTO IRPFlags (IRPFlagID, IRPFlagName, Description) 
VALUES
    (1, 'IRP_NOCACHE', 'Indicates non-cached I/O; data bypasses the system cache.'),
    (2, 'IRP_PAGING_IO', 'Indicates the I/O is for paging operations (e.g., page-in/page-out).'),
    (3, 'IRP_SYNCHRONOUS_API', 'Specifies synchronous I/O initiated by user-mode API.'),
    (4, 'IRP_SYNCHRONOUS_PAGING_IO', 'Synchronous I/O used internally for paging file operations.');

-- DROP TABLE IF EXISTS Rules;
CREATE TABLE IF NOT EXISTS Rules (
    RuleID INTEGER PRIMARY KEY AUTOINCREMENT,
    Active INTEGER NOT NULL, -- e.g Yes: 1, No: 0
    Deleted INTEGER NOT NULL, -- e.g Yes: 1, No: 0
    Action INTEGER NOT NULL, -- What type of action to take for the rule e.g. Block: 2, Alert: 1, Ignore: 0
    RuleType INTEGER NOT NULL, --Whether it is a File Hash, File Location or File Extension.
    RuleTarget INTEGER NOT NULL, -- Whether targeting the process or the operation file name
    RuleString TEXT NOT NULL -- The actual File Hash, File Location or File Extension (RULE itself)
);

-- DROP TABLE IF EXISTS RuleHistory;
CREATE TABLE IF NOT EXISTS RuleHistory (
    RuleHistoryID INTEGER PRIMARY KEY, -- ID of the rule modification.
    RuleID INTEGER NOT NULL, -- The rule that was modified.
    Acitivity TEXT NOT NULL, --Whether the Rules where created, deleted, enabled or disabled.
    Timestamp DATETIME NOT NULL, --The data and time that the rule was modified.
    FullRule TEXT NOT NULL,
    FOREIGN KEY (RuleID) REFERENCES Rules(RuleID)
);

-- =================================================================== Views ===================================================================

-- For most recent 1 minute of activity (assuming timestamps in nanoseconds since epoch) (Line Graph / Time Series)
CREATE VIEW IF NOT EXISTS View_RecentActivity AS
SELECT *
FROM MinifilterLog
WHERE PreOpTime > (SELECT MAX(PreOpTime) FROM MinifilterLog) - (60 * 1000000000); -- (1 miutes) 60 sec in ns | Future ? [600 for 10 minutes]

-- Total Operations Count
CREATE VIEW IF NOT EXISTS View_TotalOperations AS
SELECT COUNT(*) AS TotalOperations
FROM MinifilterLog;

-- Total Alerts Count
CREATE VIEW IF NOT EXISTS View_TotalAlerts AS
SELECT COUNT(*) AS TotalAlerts
FROM Alerts;

-- Plots Activity Spikes for certain operations
CREATE VIEW IF NOT EXISTS View_RecentOpsLines AS
SELECT 
    ((PreOpTime / 1000000000) / 5) * 5 AS TimeBucket,
    MajorOp,
    COUNT(*) AS Count
FROM MinifilterLog
WHERE PreOpTime > (SELECT MAX(PreOpTime) FROM MinifilterLog) - (300 * 1000000000)
GROUP BY TimeBucket, MajorOp
ORDER BY TimeBucket;

-- Operation Duration - average, lowest and highest instead (Box Plot?)
CREATE VIEW IF NOT EXISTS View_OpDurationSummary AS
SELECT 
    MajorOp,
    AVG(PostOpTime - PreOpTime) AS AvgDurationNano,
    MAX(PostOpTime - PreOpTime) AS MaxDurationNano
FROM MinifilterLog
WHERE PreOpTime IS NOT NULL AND PostOpTime IS NOT NULL
GROUP BY MajorOp;


-- Operation Breakdown (for Pie Chart)
CREATE VIEW IF NOT EXISTS View_OperationBreakdown AS
SELECT 
    MajorOp,
    MinorOp,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY MajorOp, MinorOp;

-- Kernel vs User Requested Operations (Bar Chart)
CREATE VIEW IF NOT EXISTS View_RequestorModeCount AS
SELECT 
    RequestorMode,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY RequestorMode;

-- Operation Status Frequency (Ranked Table)
CREATE VIEW IF NOT EXISTS View_OpStatusCount AS
SELECT 
    OpStatus,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY OpStatus
ORDER BY Count DESC;

-- Stacked Bar of Operation Type by Requestor Mode
CREATE VIEW IF NOT EXISTS View_OpTypeByRequestor AS
SELECT 
    OprType,
    RequestorMode,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY OprType, RequestorMode;

-- Stacked Bar of Major Operation Type by Requestor Mode
CREATE VIEW IF NOT EXISTS View_MajorOpByRequestor AS
SELECT 
    MajorOp,
    RequestorMode,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY MajorOp, RequestorMode;

-- File Operation Counts (Tree + Table)
CREATE VIEW IF NOT EXISTS View_FileOpCounts AS
SELECT 
    OpFileName,
    COUNT(*) AS Count
FROM MinifilterLog
WHERE OpFileName IS NOT NULL
GROUP BY OpFileName
ORDER BY Count DESC;

-- File Write Operations Over Time
CREATE VIEW IF NOT EXISTS View_FileWriteTiming AS
SELECT 
    OpFileName,
    PreOpTime,
    PostOpTime,
    (PostOpTime - PreOpTime) AS DurationNano
FROM MinifilterLog
WHERE MajorOp IN ('IRP_MJ_WRITE', 'IRP_MJ_CREATE', 'IRP_MJ_SET_INFORMATION');

-- Process Operation Counts
CREATE VIEW IF NOT EXISTS View_ProcessOpCounts AS
SELECT 
    ProcessId,
    ProcessFilePath,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY ProcessId, ProcessFilePath
ORDER BY Count DESC;

-- Process Threads Tree
CREATE VIEW IF NOT EXISTS View_ThreadBreakdown AS
SELECT 
    ProcessId,
    ProcessFilePath,
    ThreadId,
    COUNT(*) AS Count
FROM MinifilterLog
GROUP BY ProcessId, ThreadId;
