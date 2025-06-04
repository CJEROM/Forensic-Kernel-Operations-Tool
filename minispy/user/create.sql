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
-- INSERT INTO - (-) 
-- VALUES 
--     (-);

-- Create a new table to store major IRP (I/O Request Packet) codes
-- DROP TABLE IF EXISTS MajorIRPCodes;
CREATE TABLE IF NOT EXISTS MajorIRPCodes (
    MajorIRPCodeID INTEGER PRIMARY KEY,     -- Unique ID for each IRP code
    MajorIRPCode TEXT NOT NULL,         -- Name of the IRP operation
    Description TEXT NOT NULL          -- What the Major IRP Code is for
);
-- Insert predefined list of Major IRP codes and their corresponding IDs
-- These codes represent different types of I/O operations handled by Windows drivers
INSERT INTO MajorIRPCodes (MajorIRPCodeID, MajorIRPCode, Description) 
VALUES
    (0, 'IRP_MJ_CREATE', ""),                    -- Create/open a file or device
    (1, 'IRP_MJ_CREATE_NAMED_PIPE', ""),         -- Create a named pipe
    (2, 'IRP_MJ_CLOSE', ""),                     -- Close a handle to a file or device
    (3, 'IRP_MJ_READ', ""),                      -- Read data from a file or device
    (4, 'IRP_MJ_WRITE', ""),                     -- Write data to a file or device
    (5, 'IRP_MJ_QUERY_INFORMATION', ""),         -- Query file/device metadata
    (6, 'IRP_MJ_SET_INFORMATION', ""),           -- Set file/device metadata
    (7, 'IRP_MJ_QUERY_EA', ""),                  -- Query extended attributes
    (8, 'IRP_MJ_SET_EA', ""),                    -- Set extended attributes
    (9, 'IRP_MJ_FLUSH_BUFFERS', ""),             -- Flush buffered data to disk
    (10, 'IRP_MJ_QUERY_VOLUME_INFORMATION', ""), -- Get volume info (e.g., label, size)
    (11, 'IRP_MJ_SET_VOLUME_INFORMATION', ""),   -- Set volume information
    (12, 'IRP_MJ_DIRECTORY_CONTROL', ""),        -- Handle directory-related operations
    (13, 'IRP_MJ_FILE_SYSTEM_CONTROL', ""),      -- Filesystem-specific operations
    (14, 'IRP_MJ_DEVICE_CONTROL', ""),           -- Device-specific I/O control codes (IOCTL)
    (15, 'IRP_MJ_INTERNAL_DEVICE_CONTROL', ""),  -- Internal I/O controls (kernel mode only)
    (16, 'IRP_MJ_SHUTDOWN', ""),                 -- Prepare device for system shutdown
    (17, 'IRP_MJ_LOCK_CONTROL', ""),             -- File locking/unlocking operations
    (18, 'IRP_MJ_CLEANUP', ""),                  -- Cleanup operations before handle closure
    (19, 'IRP_MJ_CREATE_MAILSLOT', ""),          -- Create a mailslot (message-based communication)
    (20, 'IRP_MJ_QUERY_SECURITY', ""),           -- Query file or device security descriptor
    (21, 'IRP_MJ_SET_SECURITY', ""),             -- Set file or device security descriptor
    (22, 'IRP_MJ_POWER', ""),                    -- Power management (e.g., sleep/wake)
    (23, 'IRP_MJ_SYSTEM_CONTROL', ""),           -- System control requests (e.g., WMI)
    (24, 'IRP_MJ_DEVICE_CHANGE', ""),            -- Device plug/unplug notifications
    (25, 'IRP_MJ_QUERY_QUOTA', ""),              -- Query disk quota information
    (26, 'IRP_MJ_SET_QUOTA', ""),                -- Set disk quota limits
    (27, 'IRP_MJ_PNP', ""),                      -- Plug and Play notifications
    (28, 'IRP_MJ_ACQUIRE_FOR_SECTION_SYNCHRONIZATION', ""),
    (29, 'IRP_MJ_RELEASE_FOR_SECTION_SYNCHRONIZATION', ""),
    (30, 'IRP_MJ_ACQUIRE_FOR_MOD_WRITE', ""),
    (31, 'IRP_MJ_RELEASE_FOR_MOD_WRITE', ""),
    (32, 'IRP_MJ_ACQUIRE_FOR_CC_FLUSH', ""),
    (33, 'IRP_MJ_RELEASE_FOR_CC_FLUSH', ""),
    (34, 'IRP_MJ_NOTIFY_STREAM_FO_CREATION', ""),
    (35, 'IRP_MJ_FAST_IO_CHECK_IF_POSSIBLE', ""),
    (36, 'IRP_MJ_NETWORK_QUERY_OPEN', ""),
    (37, 'IRP_MJ_MDL_READ', ""),
    (38, 'IRP_MJ_MDL_READ_COMPLETE', ""),
    (39, 'IRP_MJ_PREPARE_MDL_WRITE', ""),
    (40, 'IRP_MJ_MDL_WRITE_COMPLETE', ""),
    (41, 'IRP_MJ_VOLUME_MOUNT', ""),
    (42, 'IRP_MJ_VOLUME_DISMOUNT', ""),
    (43, 'IRP_MJ_TRANSACTION_NOTIFY', "");

-- Table for Minor IRP Codes
-- DROP TABLE IF EXISTS MinorIRPCodes;
CREATE TABLE IF NOT EXISTS MinorIRPCodes (
    MinorIRPCodeID INTEGER PRIMARY KEY AUTOINCREMENT, 
    MajorIRPCodeID INT NOT NULL,
    MinorIRPCode TEXT NOT NULL,
    Link TEXT NOT NULL,
    Description TEXT NOT NULL,
    FOREIGN KEY (MajorIRPCodeID) REFERENCES MajorIRPCodes(MajorIRPCodeID)
);
INSERT INTO MinorIRPCodes (MajorIRPCodeID, MinorIRPCode, Link, Description) 
VALUES
    --+ IRP_MJ_READ (8)
    (3, 'IRP_MN_NORMAL', ""),
    (3, 'IRP_MN_DPC', ""),
    (3, 'IRP_MN_MDL', ""),
    (3, 'IRP_MN_COMPLETE', ""),
    (3, 'IRP_MN_COMPRESSED', ""),
    (3, 'IRP_MN_MDL_DPC', "", ""),
    (3, 'IRP_MN_COMPLETE_MDL', "", ""),
    (3, 'IRP_MN_COMPLETE_MDL_DPC', "", ""),
    --+ IRP_MJ_WRITE (8)
    (4, 'IRP_MN_NORMAL', ""),
    (4, 'IRP_MN_DPC', ""),
    (4, 'IRP_MN_MDL', ""),
    (4, 'IRP_MN_COMPLETEG', ""),
    (4, 'IRP_MN_COMPRESSED', ""),
    (4, 'IRP_MN_MDL_DPC', "", ""),
    (4, 'IRP_MN_COMPLETE_MD', "", ""),
    (4, 'IRP_MN_COMPLETE_MDL_DPC', "", ""),
    --+ IRP_MJ_DIRECTORY_CONTROL (2)
    (12, 'IRP_MN_QUERY_DIRECTORY', ""), 
    (12, 'IRP_MN_NOTIFY_CHANGE_DIRECTORY', ""), 
    --+ IRP_MJ_FILE_SYSTEM_CONTROL (5)
    (13, 'IRP_MN_USER_FS_REQUEST', ""), 
    (13, 'IRP_MN_MOUNT_VOLUME', ""), 
    (13, 'IRP_MN_VERIFY_VOLUME', ""), 
    (13, 'IRP_MN_LOAD_FILE_SYSTEM', ""), 
    (13, 'IRP_MN_TRACK_LINK', ""),  
    --+ IRP_MJ_DEVICE_CONTROL (1)
    (14 ,'IRP_MN_SCSI_CLASS', "", ""),
    --+ IRP_MJ_LOCK_CONTROL (4)
    (17, 'IRP_MN_LOCK', ""), 
    (17, 'IRP_MN_UNLOCK_SINGLE', ""), 
    (17, 'IRP_MN_UNLOCK_ALL', ""), 
    (17, 'IRP_MN_UNLOCK_ALL_BY_KEY', ""), 
    --+ IRP_MJ_POWER (4)
    (22, 'IRP_MN_WAIT_WAKE', ""),
    (22, 'IRP_MN_POWER_SEQUENCE', ""),
    (22, 'IRP_MN_SET_POWER', ""),
    (22, 'IRP_MN_QUERY_POWER', ""),
    --+ IRP_MJ_SYSTEM_CONTROL (10)
    (23, 'IRP_MN_QUERY_ALL_DATA', ""), 
    (23, 'IRP_MN_QUERY_SINGLE_INSTANCE', ""),
    (23, 'IRP_MN_CHANGE_SINGLE_INSTANCE', ""),
    (23, 'IRP_MN_CHANGE_SINGLE_ITEM', ""),
    (23, 'IRP_MN_ENABLE_EVENTS', ""),
    (23, 'IRP_MN_DISABLE_EVENTS', ""),
    (23, 'IRP_MN_ENABLE_COLLECTION', ""),
    (23, 'IRP_MN_DISABLE_COLLECTION', ""),
    (23, 'IRP_MN_REGINFO', ""),
    (23, 'IRP_MN_EXECUTE_METHOD', ""),
    --+ IRP_MJ_PNP (24)
    (27, 'IRP_MN_START_DEVICE', ""),
    (27, 'IRP_MN_QUERY_REMOVE_DEVICE', ""),
    (27, 'IRP_MN_REMOVE_DEVICE', ""),
    (27, 'IRP_MN_CANCEL_REMOVE_DEVICE', ""),
    (27, 'IRP_MN_STOP_DEVICE', ""),
    (27, 'IRP_MN_QUERY_STOP_DEVICE', ""),
    (27, 'IRP_MN_CANCEL_STOP_DEVICE', ""),
    (27, 'IRP_MN_QUERY_DEVICE_RELATIONS', ""),
    (27, 'IRP_MN_QUERY_INTERFACE', ""),
    (27, 'IRP_MN_QUERY_CAPABILITIES', ""),
    (27, 'IRP_MN_QUERY_RESOURCES', ""),
    (27, 'IRP_MN_QUERY_RESOURCE_REQUIREMENTS', ""),
    (27, 'IRP_MN_QUERY_DEVICE_TEXT', ""),
    (27, 'IRP_MN_FILTER_RESOURCE_REQUIREMENTS', ""),
    (27, 'IRP_MN_READ_CONFIG', ""),
    (27, 'IRP_MN_WRITE_CONFIG', ""),
    (27, 'IRP_MN_EJECT', ""),
    (27, 'IRP_MN_SET_LOCK', ""),
    (27, 'IRP_MN_QUERY_ID', ""),
    (27, 'IRP_MN_QUERY_PNP_DEVICE_STATE', ""),
    (27, 'IRP_MN_QUERY_BUS_INFORMATION', ""),
    (27, 'IRP_MN_DEVICE_USAGE_NOTIFICATION', ""),
    (27, 'IRP_MN_SURPRISE_REMOVAL', ""),
    (27, 'IRP_MN_QUERY_LEGACY_BUS_INFORMATION', ""),
    --+ IRP_MJ_TRANSACTION_NOTIFY_STRING (20)
    (43 ,'TRANSACTION_BEGIN', "", ""),
    (43 ,'TRANSACTION_NOTIFY_PREPREPARE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_PREPARE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_COMMIT', "", ""),
    (43 ,'TRANSACTION_NOTIFY_COMMIT_FINALIZE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_ROLLBACK', "", ""),
    (43 ,'TRANSACTION_NOTIFY_PREPREPARE_COMPLETE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_COMMIT_COMPLETE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_ROLLBACK_COMPLETE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_RECOVER', "", ""),
    (43 ,'TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT', "", ""),
    (43 ,'TRANSACTION_NOTIFY_DELEGATE_COMMIT', "", ""),
    (43 ,'TRANSACTION_NOTIFY_RECOVER_QUERY', "", ""),
    (43 ,'TRANSACTION_NOTIFY_ENLIST_PREPREPARE', "", ""),
    (43 ,'TRANSACTION_NOTIFY_LAST_RECOVER', "", ""),
    (43 ,'TRANSACTION_NOTIFY_INDOUBT', "", ""),
    (43 ,'TRANSACTION_NOTIFY_PROPAGATE_PULL', "", ""),
    (43 ,'TRANSACTION_NOTIFY_PROPAGATE_PUSH', "", ""),
    (43 ,'TRANSACTION_NOTIFY_MARSHAL', "", ""),
    (43 ,'TRANSACTION_NOTIFY_ENLIST_MASK', "", "");
    
-- Create the IRPFlags table
-- DROP TABLE IF EXISTS IRPFlags;
CREATE TABLE IF NOT EXISTS IRPFlags (
    IRPFlagID INTEGER PRIMARY KEY,
    IRPFlagName TEXT NOT NULL,
    Description TEXT NOT NULL
);
INSERT INTO IRPFlags (IRPFlagID, IRPFlagName, Description) 
VALUES
    (1, 'IRP_NOCACHE', ''),               
    (2, 'IRP_PAGING_IO', ''),             
    (3, 'IRP_SYNCHRONOUS_API', ''),      
    (4, 'IRP_SYNCHRONOUS_PAGING_IO', '');

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

CREATE TABLE IF NOT EXISTS ArgMapping (
    ArgMapID INTEGER PRIMARY KEY AUTOINCREMENT,
    MajorOpCode INTEGER NOT NULL,
    MinorOpCode INTEGER, -- NULL for all minors
    ArgIndex INTEGER NOT NULL, -- 1 to 6
    ArgName TEXT NOT NULL,
    Description TEXT,           -- optional, human-readable notes
    FOREIGN KEY (MajorOpCode) REFERENCES MajorIRPCodes(MajorIRPCode),
    FOREIGN KEY (MinorOpCode) REFERENCES MinorIRPCodes(MinorIRPCode)
);

INSERT INTO ArgMapping (MajorOpCode, MinorOpCode, ArgIndex, ArgName, Description)
VALUES
    --+ IRP_MJ_CREATE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_CREATE_NAMED_PIPE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_CLOSE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_READ
        --+ 
    --+ IRP_MJ_WRITE
        --+ 
    --+ IRP_MJ_QUERY_INFORMATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_SET_INFORMATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_QUERY_EA
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_SET_EA
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_FLUSH_BUFFERS
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_QUERY_VOLUME_INFORMATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
--+ IRP_MJ_SET_VOLUME_INFORMATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_DIRECTORY_CONTROL
        --+ 
    --+ IRP_MJ_FILE_SYSTEM_CONTROL
        --+ 
    --+ IRP_MJ_DEVICE_CONTROL
        --+ 
    --+ IRP_MJ_INTERNAL_DEVICE_CONTROL
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_SHUTDOWN
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_LOCK_CONTROL
        --+ 
    --+ IRP_MJ_CLEANUP
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_CREATE_MAILSLOT
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_QUERY_SECURITY
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_SET_SECURITY
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_POWER
        --+ 
    --+ IRP_MJ_SYSTEM_CONTROL
        --+ 
    --+ IRP_MJ_DEVICE_CHANGE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_QUERY_QUOTA
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_SET_QUOTA
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_PNP
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_ACQUIRE_FOR_SECTION_SYNCHRONIZATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_RELEASE_FOR_SECTION_SYNCHRONIZATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_ACQUIRE_FOR_MOD_WRITE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_RELEASE_FOR_MOD_WRITE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_ACQUIRE_FOR_CC_FLUSH
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_RELEASE_FOR_CC_FLUSH
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_NOTIFY_STREAM_FO_CREATION
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_FAST_IO_CHECK_IF_POSSIBLE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_NETWORK_QUERY_OPEN
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_MDL_READ
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_MDL_READ_COMPLETE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_PREPARE_MDL_WRITE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_MDL_WRITE_COMPLETE
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_VOLUME_MOUNT
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_VOLUME_DISMOUNT
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),
    --+ IRP_MJ_TRANSACTION_NOTIFY
        --+ 
    (, , 1, "", ""),
    (, , 2, "", ""),
    (, , 3, "", ""),
    (, , 4, "", ""),
    (, , 5, "", ""),
    (, , 6, "", ""),


-- COMMIT;

-- View for Unique operations

-- View for Unique Filesystem

-- View for Unique processes