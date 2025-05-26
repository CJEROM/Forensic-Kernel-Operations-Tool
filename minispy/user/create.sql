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

-- Idea is to store the definitions for all of the data here
-- DROP TABLE IF EXISTS Definitions;
CREATE TABLE IF NOT EXISTS Definitions (
    OperationTypeID INT PRIMARY KEY,
    OperationType TEXT
);

-- DROP TABLE IF EXISTS OperationTypes;
CREATE TABLE IF NOT EXISTS OperationTypes (
    OperationTypeID INTEGER PRIMARY KEY,
    OperationType TEXT
);
-- INSERT INTO - (-) 
-- VALUES 
--     (-);

-- Create a new table to store major IRP (I/O Request Packet) codes
-- DROP TABLE IF EXISTS MajorIRPCodes;
CREATE TABLE IF NOT EXISTS MajorIRPCodes (
    MajorIRPCodeID INTEGER PRIMARY KEY,     -- Unique ID for each IRP code
    MajorIRPCode TEXT NOT NULL,         -- Name of the IRP operation
    Description TEXT           -- What the Major IRP Code is for
);
-- Insert predefined list of Major IRP codes and their corresponding IDs
-- These codes represent different types of I/O operations handled by Windows drivers
INSERT INTO MajorIRPCodes (MajorIRPCodeID, MajorIRPCode) 
VALUES
    (0, 'IRP_MJ_CREATE'),                    -- Create/open a file or device
    (1, 'IRP_MJ_CREATE_NAMED_PIPE'),         -- Create a named pipe
    (2, 'IRP_MJ_CLOSE'),                     -- Close a handle to a file or device
    (3, 'IRP_MJ_READ'),                      -- Read data from a file or device
    (4, 'IRP_MJ_WRITE'),                     -- Write data to a file or device
    (5, 'IRP_MJ_QUERY_INFORMATION'),         -- Query file/device metadata
    (6, 'IRP_MJ_SET_INFORMATION'),           -- Set file/device metadata
    (7, 'IRP_MJ_QUERY_EA'),                  -- Query extended attributes
    (8, 'IRP_MJ_SET_EA'),                    -- Set extended attributes
    (9, 'IRP_MJ_FLUSH_BUFFERS'),             -- Flush buffered data to disk
    (10, 'IRP_MJ_QUERY_VOLUME_INFORMATION'), -- Get volume info (e.g., label, size)
    (11, 'IRP_MJ_SET_VOLUME_INFORMATION'),   -- Set volume information
    (12, 'IRP_MJ_DIRECTORY_CONTROL'),        -- Handle directory-related operations
    (13, 'IRP_MJ_FILE_SYSTEM_CONTROL'),      -- Filesystem-specific operations
    (14, 'IRP_MJ_DEVICE_CONTROL'),           -- Device-specific I/O control codes (IOCTL)
    (15, 'IRP_MJ_INTERNAL_DEVICE_CONTROL'),  -- Internal I/O controls (kernel mode only)
    (16, 'IRP_MJ_SHUTDOWN'),                 -- Prepare device for system shutdown
    (17, 'IRP_MJ_LOCK_CONTROL'),             -- File locking/unlocking operations
    (18, 'IRP_MJ_CLEANUP'),                  -- Cleanup operations before handle closure
    (19, 'IRP_MJ_CREATE_MAILSLOT'),          -- Create a mailslot (message-based communication)
    (20, 'IRP_MJ_QUERY_SECURITY'),           -- Query file or device security descriptor
    (21, 'IRP_MJ_SET_SECURITY'),             -- Set file or device security descriptor
    (22, 'IRP_MJ_POWER'),                    -- Power management (e.g., sleep/wake)
    (23, 'IRP_MJ_SYSTEM_CONTROL'),           -- System control requests (e.g., WMI)
    (24, 'IRP_MJ_DEVICE_CHANGE'),            -- Device plug/unplug notifications
    (25, 'IRP_MJ_QUERY_QUOTA'),              -- Query disk quota information
    (26, 'IRP_MJ_SET_QUOTA'),                -- Set disk quota limits
    (27, 'IRP_MJ_PNP');                      -- Plug and Play notifications

-- Table for Minor IRP Codes
-- DROP TABLE IF EXISTS MinorIRPCodes;
CREATE TABLE IF NOT EXISTS MinorIRPCodes (
    MinorIRPCodeID INTEGER PRIMARY KEY,
    MajorIRPCodeID INT NOT NULL,
    MinorIRPCode TEXT NOT NULL,
    FOREIGN KEY (MajorIRPCodeID) REFERENCES MajorIRPCodes(MajorIRPCodeID)
);
INSERT INTO MinorIRPCodes (MinorIRPCodeID, MajorIRPCodeID, MinorIRPCode) 
VALUES
    --+ IRP_MJ_DIRECTORY_CONTROL
    (0, 12, 'IRP_MN_QUERY_DIRECTORY'), 
    (2, 12, 'IRP_MN_NOTIFY_CHANGE_DIRECTORY'), 
    --+ IRP_MJ_FILE_SYSTEM_CONTROL
    (3, 13, 'IRP_MN_USER_FS_REQUEST'), 
    (4, 13, 'IRP_MN_MOUNT_VOLUME'), 
    (5, 13, 'IRP_MN_VERIFY_VOLUME'), 
    (6, 13, 'IRP_MN_LOAD_FILE_SYSTEM'), 
    (7, 13, 'IRP_MN_TRACK_LINK'), 
    --+ IRP_MJ_LOCK_CONTROL
    (8, 17, 'IRP_MN_LOCK'), 
    (9, 17, 'IRP_MN_UNLOCK_SINGLE'), 
    (10, 17, 'IRP_MN_UNLOCK_ALL'), 
    (11, 17, 'IRP_MN_UNLOCK_ALL_BY_KEY'), 
    --+ IRP_MJ_READ
    (12, 3, 'IRP_MN_NORMAL'),
    (13, 3, 'IRP_MN_DPC'),
    (14, 3, 'IRP_MN_MDL'),
    (15, 3, 'IRP_MN_COMPLETE'),
    (16, 3, 'IRP_MN_COMPRESSED'),
    --+ IRP_MJ_WRITE
    (17, 4, 'IRP_MN_NORMAL'),
    (18, 4, 'IRP_MN_DPC'),
    (19, 4, 'IRP_MN_MDL'),
    (20, 4, 'IRP_MN_COMPLETE'),
    (21, 4, 'IRP_MN_COMPRESSED'),
    --+ IRP_MJ_PNP
    (22, 27, 'IRP_MN_START_DEVICE'),
    (23, 27, 'IRP_MN_QUERY_REMOVE_DEVICE'),
    (24, 27, 'IRP_MN_REMOVE_DEVICE'),
    (25, 27, 'IRP_MN_CANCEL_REMOVE_DEVICE'),
    (26, 27, 'IRP_MN_STOP_DEVICE'),
    (27, 27, 'IRP_MN_QUERY_STOP_DEVICE'),
    (28, 27, 'IRP_MN_CANCEL_STOP_DEVICE'),
    (29, 27, 'IRP_MN_QUERY_DEVICE_RELATIONS'),
    (30, 27, 'IRP_MN_QUERY_INTERFACE'),
    (31, 27, 'IRP_MN_QUERY_CAPABILITIES'),
    (32, 27, 'IRP_MN_QUERY_RESOURCES'),
    (33, 27, 'IRP_MN_QUERY_RESOURCE_REQUIREMENTS'),
    (34, 27, 'IRP_MN_QUERY_DEVICE_TEXT'),
    (35, 27, 'IRP_MN_FILTER_RESOURCE_REQUIREMENTS'),
    (36, 27, 'IRP_MN_READ_CONFIG'),
    (37, 27, 'IRP_MN_WRITE_CONFIG'),
    (38, 27, 'IRP_MN_EJECT'),
    (39, 27, 'IRP_MN_SET_LOCK'),
    (40, 27, 'IRP_MN_QUERY_ID'),
    (41, 27, 'IRP_MN_QUERY_PNP_DEVICE_STATE'),
    (42, 27, 'IRP_MN_QUERY_BUS_INFORMATION'),
    (43, 27, 'IRP_MN_DEVICE_USAGE_NOTIFICATION'),
    (44, 27, 'IRP_MN_SURPRISE_REMOVAL'),
    (45, 27, 'IRP_MN_QUERY_LEGACY_BUS_INFORMATION'),
    --+ IRP_MJ_POWER
    (46, 22, 'IRP_MN_WAIT_WAKE'),
    (47, 22, 'IRP_MN_POWER_SEQUENCE'),
    (48, 22, 'IRP_MN_SET_POWER'),
    (49, 22, 'IRP_MN_QUERY_POWER'),
    --+ IRP_MJ_SYSTEM_CONTROL
    (50, 23, 'IRP_MN_QUERY_ALL_DATA'), 
    (51, 23, 'IRP_MN_QUERY_SINGLE_INSTANCE'),
    (52, 23, 'IRP_MN_CHANGE_SINGLE_INSTANCE'),
    (53, 23, 'IRP_MN_CHANGE_SINGLE_ITEM'),
    (54, 23, 'IRP_MN_ENABLE_EVENTS'),
    (55, 23, 'IRP_MN_DISABLE_EVENTS'),
    (56, 23, 'IRP_MN_ENABLE_COLLECTION'),
    (57, 23, 'IRP_MN_DISABLE_COLLECTION'),
    (58, 23, 'IRP_MN_REGINFO'),
    (59, 23, 'IRP_MN_EXECUTE_METHOD');

-- Create the IRPFlags table
-- DROP TABLE IF EXISTS IRPFlags;
CREATE TABLE IF NOT EXISTS IRPFlags (
    IRPFlagID INTEGER PRIMARY KEY,
    IRPFlagName TEXT NOT NULL,
    Description TEXT
);
INSERT INTO IRPFlags (IRPFlagID, IRPFlagName, Description) VALUES
    (1, 'IRP_NOCACHE', ''),               
    (2, 'IRP_PAGING_IO', ''),             
    (3, 'IRP_SYNCHRONOUS_API', ''),      
    (4, 'IRP_SYNCHRONOUS_PAGING_IO', '');

-- DROP TABLE IF EXISTS RuleHistory;
CREATE TABLE IF NOT EXISTS RuleHistory (
    RuleHistoryID INTEGER PRIMARY KEY, -- ID of the rule modification.
    RuleID INTEGER NOT NULL, -- The rule that was modified.
    Acitivity TEXT NOT NULL, --Whether the Rules where created, deleted, enabled or disabled.
    Timestamp DATETIME NOT NULL, --The data and time that the rule was modified.
    FOREIGN KEY (RuleID) REFERENCES Rules(RuleID)
);

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
-- INSERT INTO - (-) 
-- VALUES 
--     (-);

-- DROP TABLE IF EXISTS Alerts;
CREATE TABLE IF NOT EXISTS Alerts (
    AlertID INTEGER PRIMARY KEY AUTOINCREMENT,
    Timestamp DATETIME NOT NULL,
    AlertMessage TEXT                                       -- Human-readable explanation
);

CREATE TABLE IF NOT EXISTS ArgMapping (
    MajorOpCode INTEGER NOT NULL,
    MinorOpCode INTEGER, -- NULL for all minors
    ArgIndex INTEGER NOT NULL, -- 1 to 6
    ArgName TEXT NOT NULL,
    Description TEXT,           -- optional, human-readable notes
    PRIMARY KEY (MajorOpCode, MinorOpCode, ArgIndex)
);

-- COMMIT;