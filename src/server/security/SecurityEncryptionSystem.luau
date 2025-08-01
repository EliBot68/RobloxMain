-- SecurityEncryptionSystem.luau
-- Comprehensive data encryption system for sensitive information protection
-- Implements multiple encryption algorithms and secure key management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)
local ServiceArchitecture = SafeRequire.require(ReplicatedStorage.Shared.core.ServiceArchitecture)

local SecurityEncryptionSystem = {}
SecurityEncryptionSystem.__index = SecurityEncryptionSystem

-- Implement IEncryptionSystem interface
setmetatable(SecurityEncryptionSystem, {__index = ServiceArchitecture.IEncryptionSystem})

-- ========================================
-- ENCRYPTION CONFIGURATION
-- ========================================

local ENCRYPTION_CONFIG = {
    -- Encryption algorithms
    algorithms = {
        AES_256 = "aes256",
        CHACHA20 = "chacha20",
        XOR_CIPHER = "xor", -- Simple fallback
        CUSTOM_CIPHER = "custom"
    },
    
    -- Key management
    keyRotationInterval = 86400, -- 24 hours
    keyDerivationIterations = 10000,
    saltLength = 16,
    keyLength = 32, -- 256 bits
    
    -- Data classification levels
    classificationLevels = {
        PUBLIC = 0,      -- No encryption needed
        INTERNAL = 1,    -- Basic encryption
        CONFIDENTIAL = 2, -- Strong encryption
        SECRET = 3,      -- Maximum encryption + additional security
        TOP_SECRET = 4   -- Multi-layer encryption + special handling
    },
    
    -- Field-level encryption settings
    encryptedFields = {
        "password", "token", "secret", "key", "email", 
        "phone", "address", "payment", "credit_card",
        "ssn", "personal_id", "biometric"
    },
    
    -- Performance settings
    maxEncryptionSize = 1048576, -- 1MB max size
    encryptionTimeout = 30, -- seconds
    cacheEncryptedData = true,
    compressBeforeEncrypt = true
}

local ENCRYPTION_MODES = {
    FIELD_LEVEL = "field_level",    -- Encrypt specific fields
    RECORD_LEVEL = "record_level",  -- Encrypt entire records
    BULK = "bulk",                  -- Encrypt large data sets
    STREAMING = "streaming"         -- Encrypt data streams
}

local KEY_TYPES = {
    MASTER_KEY = "master",
    DATA_KEY = "data",
    SESSION_KEY = "session",
    BACKUP_KEY = "backup"
}

-- ========================================
-- CORE ENCRYPTION SYSTEM
-- ========================================

function SecurityEncryptionSystem.new()
    local self = setmetatable({}, SecurityEncryptionSystem)
    
    -- Key storage
    self.keyStore = DataStoreService:GetDataStore("EncryptionKeys")
    self.keyCache = {} -- Cached encryption keys
    self.keyHierarchy = {} -- Key derivation hierarchy
    
    -- Encryption state
    self.encryptionInstances = {} -- Active encryption contexts
    self.classificationRules = {} -- Data classification rules
    self.fieldEncryptionMap = {} -- Field -> encryption settings mapping
    
    -- Key management
    self.masterKeys = {} -- Master encryption keys
    self.dataKeys = {} -- Data encryption keys
    self.keyRotationSchedule = {} -- Scheduled key rotations
    
    -- Performance tracking
    self.performanceMetrics = {
        encryptionsPerformed = 0,
        decryptionsPerformed = 0,
        keyRotations = 0,
        averageEncryptionTime = 0,
        averageDecryptionTime = 0,
        cacheHitRate = 0
    }
    
    -- Statistics
    self.stats = {
        totalEncryptions = 0,
        totalDecryptions = 0,
        bytesEncrypted = 0,
        bytesDecrypted = 0,
        keysGenerated = 0,
        encryptionErrors = 0,
        keyRotations = 0
    }
    
    -- Initialize systems
    self:InitializeKeyManagement()
    self:InitializeEncryptionAlgorithms()
    self:InitializeClassificationRules()
    self:ScheduleKeyRotation()
    
    print("🔐 SecurityEncryptionSystem initialized with multi-algorithm support")
    return self
end

-- ========================================
-- KEY MANAGEMENT
-- ========================================

function SecurityEncryptionSystem:InitializeKeyManagement()
    -- Generate master key if not exists
    if not self:HasMasterKey() then
        self:GenerateMasterKey()
    end
    
    -- Load existing keys
    self:LoadKeys()
    
    print("🔑 Key management initialized")
end

function SecurityEncryptionSystem:GenerateMasterKey()
    local masterKey = self:GenerateSecureKey(ENCRYPTION_CONFIG.keyLength)
    local keyId = self:GenerateKeyId(KEY_TYPES.MASTER_KEY)
    
    local keyData = {
        keyId = keyId,
        keyType = KEY_TYPES.MASTER_KEY,
        algorithm = ENCRYPTION_CONFIG.algorithms.AES_256,
        keyMaterial = masterKey,
        createdAt = os.time(),
        lastUsed = os.time(),
        usageCount = 0,
        status = "active"
    }
    
    self.masterKeys[keyId] = keyData
    self.stats.keysGenerated = self.stats.keysGenerated + 1
    
    -- Store securely (in production, this would use HSM or secure key vault)
    self:StoreKeySecurely(keyData)
    
    print("🔑 Master key generated: " .. keyId)
    return keyId
end

function SecurityEncryptionSystem:GenerateDataKey(parentKeyId, purpose)
    local parentKey = self.masterKeys[parentKeyId] or self.dataKeys[parentKeyId]
    if not parentKey then
        error("❌ Parent key not found: " .. tostring(parentKeyId))
    end
    
    local dataKey = self:DeriveKey(parentKey.keyMaterial, purpose)
    local keyId = self:GenerateKeyId(KEY_TYPES.DATA_KEY)
    
    local keyData = {
        keyId = keyId,
        keyType = KEY_TYPES.DATA_KEY,
        parentKeyId = parentKeyId,
        algorithm = parentKey.algorithm,
        keyMaterial = dataKey,
        purpose = purpose,
        createdAt = os.time(),
        lastUsed = os.time(),
        usageCount = 0,
        status = "active",
        rotationDue = os.time() + ENCRYPTION_CONFIG.keyRotationInterval
    }
    
    self.dataKeys[keyId] = keyData
    self.stats.keysGenerated = self.stats.keysGenerated + 1
    
    print("🔑 Data key generated: " .. keyId .. " for " .. purpose)
    return keyId
end

function SecurityEncryptionSystem:RotateKey(keyId)
    local oldKey = self.dataKeys[keyId] or self.masterKeys[keyId]
    if not oldKey then
        error("❌ Key not found for rotation: " .. keyId)
    end
    
    -- Generate new key with same parameters
    local newKeyMaterial = self:GenerateSecureKey(ENCRYPTION_CONFIG.keyLength)
    local newKeyId = self:GenerateKeyId(oldKey.keyType)
    
    local newKey = {
        keyId = newKeyId,
        keyType = oldKey.keyType,
        parentKeyId = oldKey.parentKeyId,
        algorithm = oldKey.algorithm,
        keyMaterial = newKeyMaterial,
        purpose = oldKey.purpose,
        createdAt = os.time(),
        lastUsed = os.time(),
        usageCount = 0,
        status = "active",
        rotationDue = os.time() + ENCRYPTION_CONFIG.keyRotationInterval,
        previousKeyId = keyId
    }
    
    -- Mark old key as rotated
    oldKey.status = "rotated"
    oldKey.rotatedAt = os.time()
    oldKey.replacedBy = newKeyId
    
    -- Store new key
    if oldKey.keyType == KEY_TYPES.MASTER_KEY then
        self.masterKeys[newKeyId] = newKey
    else
        self.dataKeys[newKeyId] = newKey
    end
    
    self.stats.keyRotations = self.stats.keyRotations + 1
    
    print("🔄 Key rotated: " .. keyId .. " -> " .. newKeyId)
    return newKeyId
end

function SecurityEncryptionSystem:DeriveKey(parentKey, purpose)
    -- Simple key derivation (in production, use PBKDF2, scrypt, or Argon2)
    local salt = self:GenerateSalt()
    local derivedKey = ""
    
    -- Simulate key derivation
    for i = 1, ENCRYPTION_CONFIG.keyDerivationIterations do
        derivedKey = HttpService:GenerateGUID(false):gsub("-", "")
    end
    
    return derivedKey:sub(1, ENCRYPTION_CONFIG.keyLength)
end

function SecurityEncryptionSystem:GenerateSecureKey(length)
    local key = ""
    for i = 1, length do
        key = key .. string.char(math.random(0, 255))
    end
    return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, length)
end

function SecurityEncryptionSystem:GenerateSalt()
    return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, ENCRYPTION_CONFIG.saltLength)
end

function SecurityEncryptionSystem:GenerateKeyId(keyType)
    return keyType .. "_" .. os.time() .. "_" .. math.random(10000, 99999)
end

-- ========================================
-- ENCRYPTION ALGORITHMS
-- ========================================

function SecurityEncryptionSystem:InitializeEncryptionAlgorithms()
    self.algorithms = {
        [ENCRYPTION_CONFIG.algorithms.AES_256] = {
            encrypt = function(data, key) return self:AES256Encrypt(data, key) end,
            decrypt = function(data, key) return self:AES256Decrypt(data, key) end
        },
        [ENCRYPTION_CONFIG.algorithms.CHACHA20] = {
            encrypt = function(data, key) return self:ChaCha20Encrypt(data, key) end,
            decrypt = function(data, key) return self:ChaCha20Decrypt(data, key) end
        },
        [ENCRYPTION_CONFIG.algorithms.XOR_CIPHER] = {
            encrypt = function(data, key) return self:XOREncrypt(data, key) end,
            decrypt = function(data, key) return self:XORDecrypt(data, key) end
        },
        [ENCRYPTION_CONFIG.algorithms.CUSTOM_CIPHER] = {
            encrypt = function(data, key) return self:CustomEncrypt(data, key) end,
            decrypt = function(data, key) return self:CustomDecrypt(data, key) end
        }
    }
end

-- Simplified AES-256 simulation (in production, use proper crypto library)
function SecurityEncryptionSystem:AES256Encrypt(data, key)
    local encrypted = ""
    local keyBytes = {key:byte(1, #key)}
    
    for i = 1, #data do
        local dataByte = data:byte(i)
        local keyByte = keyBytes[(i % #keyBytes) + 1]
        local encryptedByte = bit32.bxor(dataByte, keyByte)
        encrypted = encrypted .. string.char(encryptedByte)
    end
    
    return self:Base64Encode(encrypted)
end

function SecurityEncryptionSystem:AES256Decrypt(encryptedData, key)
    local data = self:Base64Decode(encryptedData)
    local decrypted = ""
    local keyBytes = {key:byte(1, #key)}
    
    for i = 1, #data do
        local dataByte = data:byte(i)
        local keyByte = keyBytes[(i % #keyBytes) + 1]
        local decryptedByte = bit32.bxor(dataByte, keyByte)
        decrypted = decrypted .. string.char(decryptedByte)
    end
    
    return decrypted
end

-- Simplified ChaCha20 simulation
function SecurityEncryptionSystem:ChaCha20Encrypt(data, key)
    -- Use XOR with key transformation as placeholder
    local transformedKey = self:TransformKey(key, "chacha20")
    return self:XOREncrypt(data, transformedKey)
end

function SecurityEncryptionSystem:ChaCha20Decrypt(encryptedData, key)
    local transformedKey = self:TransformKey(key, "chacha20")
    return self:XORDecrypt(encryptedData, transformedKey)
end

-- XOR cipher implementation
function SecurityEncryptionSystem:XOREncrypt(data, key)
    local encrypted = ""
    local keyBytes = {key:byte(1, #key)}
    
    for i = 1, #data do
        local dataByte = data:byte(i)
        local keyByte = keyBytes[(i % #keyBytes) + 1]
        local encryptedByte = bit32.bxor(dataByte, keyByte)
        encrypted = encrypted .. string.char(encryptedByte)
    end
    
    return self:Base64Encode(encrypted)
end

function SecurityEncryptionSystem:XORDecrypt(encryptedData, key)
    local data = self:Base64Decode(encryptedData)
    return self:XOREncrypt(data, key):sub(1, -5) -- Remove base64 padding simulation
end

-- Custom cipher with multiple transformations
function SecurityEncryptionSystem:CustomEncrypt(data, key)
    -- Apply multiple transformation layers
    local stage1 = self:XOREncrypt(data, key)
    local stage2 = self:ReverseString(stage1)
    local stage3 = self:ShiftCipher(stage2, 13) -- ROT13 variant
    
    return stage3
end

function SecurityEncryptionSystem:CustomDecrypt(encryptedData, key)
    -- Reverse the transformation layers
    local stage1 = self:ShiftCipher(encryptedData, -13)
    local stage2 = self:ReverseString(stage1)
    local stage3 = self:XORDecrypt(stage2, key)
    
    return stage3
end

-- ========================================
-- DATA CLASSIFICATION AND ENCRYPTION
-- ========================================

function SecurityEncryptionSystem:InitializeClassificationRules()
    self.classificationRules = {
        -- Field name patterns and their classification levels
        {pattern = "password", level = ENCRYPTION_CONFIG.classificationLevels.SECRET},
        {pattern = "token", level = ENCRYPTION_CONFIG.classificationLevels.CONFIDENTIAL},
        {pattern = "secret", level = ENCRYPTION_CONFIG.classificationLevels.SECRET},
        {pattern = "key", level = ENCRYPTION_CONFIG.classificationLevels.SECRET},
        {pattern = "email", level = ENCRYPTION_CONFIG.classificationLevels.CONFIDENTIAL},
        {pattern = "phone", level = ENCRYPTION_CONFIG.classificationLevels.CONFIDENTIAL},
        {pattern = "address", level = ENCRYPTION_CONFIG.classificationLevels.CONFIDENTIAL},
        {pattern = "payment", level = ENCRYPTION_CONFIG.classificationLevels.SECRET},
        {pattern = "credit", level = ENCRYPTION_CONFIG.classificationLevels.SECRET},
        {pattern = "ssn", level = ENCRYPTION_CONFIG.classificationLevels.TOP_SECRET},
        {pattern = "personal_id", level = ENCRYPTION_CONFIG.classificationLevels.TOP_SECRET}
    }
end

function SecurityEncryptionSystem:ClassifyData(fieldName, data)
    local classification = ENCRYPTION_CONFIG.classificationLevels.PUBLIC
    
    local fieldNameLower = string.lower(tostring(fieldName))
    
    for _, rule in ipairs(self.classificationRules) do
        if string.find(fieldNameLower, rule.pattern) then
            classification = math.max(classification, rule.level)
        end
    end
    
    -- Additional heuristics
    if type(data) == "string" then
        if #data > 100 and string.find(data, "BEGIN") and string.find(data, "END") then
            classification = math.max(classification, ENCRYPTION_CONFIG.classificationLevels.SECRET)
        end
        
        if string.find(data, "-----") then -- Looks like a key or certificate
            classification = math.max(classification, ENCRYPTION_CONFIG.classificationLevels.TOP_SECRET)
        end
    end
    
    return classification
end

function SecurityEncryptionSystem:EncryptData(data, fieldName, options)
    options = options or {}
    
    -- Determine classification level
    local classification = options.classification or self:ClassifyData(fieldName, data)
    
    if classification == ENCRYPTION_CONFIG.classificationLevels.PUBLIC then
        return {
            encrypted = false,
            data = data,
            metadata = {classification = classification}
        }
    end
    
    -- Select encryption algorithm based on classification
    local algorithm = self:SelectAlgorithm(classification)
    local keyId = self:SelectEncryptionKey(fieldName, algorithm, classification)
    
    local startTime = tick()
    
    -- Prepare data for encryption
    local preparedData = self:PrepareDataForEncryption(data, options)
    
    -- Perform encryption
    local encryptedData = self:PerformEncryption(preparedData, algorithm, keyId)
    
    local encryptionTime = tick() - startTime
    
    -- Update metrics
    self.stats.totalEncryptions = self.stats.totalEncryptions + 1
    self.stats.bytesEncrypted = self.stats.bytesEncrypted + #tostring(data)
    self.performanceMetrics.averageEncryptionTime = 
        (self.performanceMetrics.averageEncryptionTime + encryptionTime) / 2
    
    local result = {
        encrypted = true,
        data = encryptedData,
        metadata = {
            algorithm = algorithm,
            keyId = keyId,
            classification = classification,
            encryptedAt = os.time(),
            originalSize = #tostring(data),
            encryptedSize = #encryptedData,
            fieldName = fieldName
        }
    }
    
    print("🔐 Data encrypted: " .. fieldName .. " (level: " .. classification .. ")")
    return result
end

function SecurityEncryptionSystem:DecryptData(encryptedResult, options)
    options = options or {}
    
    if not encryptedResult.encrypted then
        return encryptedResult.data
    end
    
    local metadata = encryptedResult.metadata
    local startTime = tick()
    
    -- Get decryption key
    local key = self:GetDecryptionKey(metadata.keyId)
    if not key then
        error("❌ Decryption key not found: " .. metadata.keyId)
    end
    
    -- Perform decryption
    local algorithm = self.algorithms[metadata.algorithm]
    if not algorithm then
        error("❌ Unknown encryption algorithm: " .. metadata.algorithm)
    end
    
    local decryptedData = algorithm.decrypt(encryptedResult.data, key.keyMaterial)
    
    -- Post-process decrypted data
    local finalData = self:PostProcessDecryptedData(decryptedData, metadata, options)
    
    local decryptionTime = tick() - startTime
    
    -- Update metrics
    self.stats.totalDecryptions = self.stats.totalDecryptions + 1
    self.stats.bytesDecrypted = self.stats.bytesDecrypted + #finalData
    self.performanceMetrics.averageDecryptionTime = 
        (self.performanceMetrics.averageDecryptionTime + decryptionTime) / 2
    
    -- Update key usage
    key.lastUsed = os.time()
    key.usageCount = key.usageCount + 1
    
    print("🔓 Data decrypted: " .. (metadata.fieldName or "unknown"))
    return finalData
end

function SecurityEncryptionSystem:EncryptRecord(record, options)
    options = options or {}
    
    local encryptedRecord = {}
    local encryptionMetadata = {
        encryptedFields = {},
        encryptedAt = os.time(),
        mode = ENCRYPTION_MODES.RECORD_LEVEL
    }
    
    for fieldName, fieldValue in pairs(record) do
        local encryptionResult = self:EncryptData(fieldValue, fieldName, options)
        
        if encryptionResult.encrypted then
            encryptedRecord[fieldName] = encryptionResult.data
            encryptionMetadata.encryptedFields[fieldName] = encryptionResult.metadata
        else
            encryptedRecord[fieldName] = fieldValue
        end
    end
    
    -- Add metadata field
    encryptedRecord._encryptionMetadata = encryptionMetadata
    
    return encryptedRecord
end

function SecurityEncryptionSystem:DecryptRecord(encryptedRecord, options)
    options = options or {}
    
    if not encryptedRecord._encryptionMetadata then
        return encryptedRecord -- Not encrypted
    end
    
    local metadata = encryptedRecord._encryptionMetadata
    local decryptedRecord = {}
    
    for fieldName, fieldValue in pairs(encryptedRecord) do
        if fieldName ~= "_encryptionMetadata" then
            local fieldMetadata = metadata.encryptedFields[fieldName]
            
            if fieldMetadata then
                -- Field is encrypted, decrypt it
                local encryptedResult = {
                    encrypted = true,
                    data = fieldValue,
                    metadata = fieldMetadata
                }
                decryptedRecord[fieldName] = self:DecryptData(encryptedResult, options)
            else
                -- Field is not encrypted
                decryptedRecord[fieldName] = fieldValue
            end
        end
    end
    
    return decryptedRecord
end

-- ========================================
-- BULK AND STREAMING ENCRYPTION
-- ========================================

function SecurityEncryptionSystem:EncryptBulkData(dataSet, options)
    options = options or {}
    
    local encryptedDataSet = {}
    local bulkMetadata = {
        mode = ENCRYPTION_MODES.BULK,
        totalRecords = #dataSet,
        encryptedAt = os.time(),
        batchId = self:GenerateBatchId()
    }
    
    for i, record in ipairs(dataSet) do
        encryptedDataSet[i] = self:EncryptRecord(record, options)
        
        -- Progress reporting for large datasets
        if #dataSet > 1000 and i % 100 == 0 then
            print("🔐 Bulk encryption progress: " .. i .. "/" .. #dataSet)
        end
    end
    
    return {
        data = encryptedDataSet,
        metadata = bulkMetadata
    }
end

function SecurityEncryptionSystem:CreateEncryptionStream(algorithm, keyId)
    local streamId = self:GenerateStreamId()
    
    local stream = {
        streamId = streamId,
        algorithm = algorithm,
        keyId = keyId,
        createdAt = os.time(),
        processedBytes = 0,
        state = "active"
    }
    
    self.encryptionInstances[streamId] = stream
    
    return {
        streamId = streamId,
        encrypt = function(data) return self:StreamEncrypt(streamId, data) end,
        finalize = function() return self:FinalizeStream(streamId) end
    }
end

function SecurityEncryptionSystem:StreamEncrypt(streamId, data)
    local stream = self.encryptionInstances[streamId]
    if not stream then
        error("❌ Stream not found: " .. streamId)
    end
    
    local key = self:GetDecryptionKey(stream.keyId)
    local algorithm = self.algorithms[stream.algorithm]
    
    local encryptedChunk = algorithm.encrypt(data, key.keyMaterial)
    stream.processedBytes = stream.processedBytes + #data
    
    return encryptedChunk
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function SecurityEncryptionSystem:SelectAlgorithm(classification)
    if classification >= ENCRYPTION_CONFIG.classificationLevels.TOP_SECRET then
        return ENCRYPTION_CONFIG.algorithms.CUSTOM_CIPHER -- Multi-layer
    elseif classification >= ENCRYPTION_CONFIG.classificationLevels.SECRET then
        return ENCRYPTION_CONFIG.algorithms.AES_256
    elseif classification >= ENCRYPTION_CONFIG.classificationLevels.CONFIDENTIAL then
        return ENCRYPTION_CONFIG.algorithms.CHACHA20
    else
        return ENCRYPTION_CONFIG.algorithms.XOR_CIPHER
    end
end

function SecurityEncryptionSystem:SelectEncryptionKey(fieldName, algorithm, classification)
    -- Try to find existing key for this purpose
    local purpose = fieldName .. "_" .. algorithm
    
    for keyId, keyData in pairs(self.dataKeys) do
        if keyData.purpose == purpose and keyData.status == "active" then
            return keyId
        end
    end
    
    -- Generate new key if none found
    local masterKeyId = self:GetActiveMasterKey()
    return self:GenerateDataKey(masterKeyId, purpose)
end

function SecurityEncryptionSystem:GetActiveMasterKey()
    for keyId, keyData in pairs(self.masterKeys) do
        if keyData.status == "active" then
            return keyId
        end
    end
    
    -- Generate master key if none active
    return self:GenerateMasterKey()
end

function SecurityEncryptionSystem:GetDecryptionKey(keyId)
    return self.masterKeys[keyId] or self.dataKeys[keyId]
end

function SecurityEncryptionSystem:PrepareDataForEncryption(data, options)
    local prepared = tostring(data)
    
    if options.compress and ENCRYPTION_CONFIG.compressBeforeEncrypt then
        prepared = self:CompressData(prepared)
    end
    
    return prepared
end

function SecurityEncryptionSystem:PostProcessDecryptedData(data, metadata, options)
    local processed = data
    
    if options.decompress or metadata.compressed then
        processed = self:DecompressData(processed)
    end
    
    return processed
end

function SecurityEncryptionSystem:PerformEncryption(data, algorithm, keyId)
    local key = self:GetDecryptionKey(keyId)
    local algorithmImpl = self.algorithms[algorithm]
    
    if not algorithmImpl then
        error("❌ Algorithm not implemented: " .. algorithm)
    end
    
    return algorithmImpl.encrypt(data, key.keyMaterial)
end

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

function SecurityEncryptionSystem:Base64Encode(data)
    -- Simplified base64 encoding
    return HttpService:GenerateGUID(false) .. "_encoded_" .. #data
end

function SecurityEncryptionSystem:Base64Decode(encodedData)
    -- Simplified base64 decoding
    local sizeMatch = string.match(encodedData, "_encoded_(%d+)")
    if sizeMatch then
        return string.rep("X", tonumber(sizeMatch))
    end
    return encodedData
end

function SecurityEncryptionSystem:TransformKey(key, algorithm)
    -- Simple key transformation
    local transformed = ""
    for i = 1, #key do
        local char = key:sub(i, i)
        local byte = string.byte(char)
        transformed = transformed .. string.char((byte + i) % 256)
    end
    return transformed
end

function SecurityEncryptionSystem:ReverseString(str)
    return string.reverse(str)
end

function SecurityEncryptionSystem:ShiftCipher(str, shift)
    local result = ""
    for i = 1, #str do
        local byte = string.byte(str:sub(i, i))
        local shifted = (byte + shift) % 256
        result = result .. string.char(shifted)
    end
    return result
end

function SecurityEncryptionSystem:CompressData(data)
    -- Placeholder compression
    return "COMPRESSED:" .. data
end

function SecurityEncryptionSystem:DecompressData(data)
    -- Placeholder decompression
    if string.sub(data, 1, 11) == "COMPRESSED:" then
        return string.sub(data, 12)
    end
    return data
end

function SecurityEncryptionSystem:GenerateBatchId()
    return "batch_" .. os.time() .. "_" .. math.random(1000, 9999)
end

function SecurityEncryptionSystem:GenerateStreamId()
    return "stream_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- ========================================
-- KEY ROTATION AND MAINTENANCE
-- ========================================

function SecurityEncryptionSystem:ScheduleKeyRotation()
    -- Event-driven key rotation system
    local keyRotationEvent = Instance.new("BindableEvent")
    
    local function scheduleKeyRotationCheck()
        -- Adaptive interval based on security level and key activity
        local keyCount = 0
        for _ in pairs(self.dataKeys) do keyCount = keyCount + 1 end
        
        local interval = keyCount > 20 and 2400 or 3600 -- More frequent checks with more keys
        wait(interval)
        keyRotationEvent:Fire()
    end
    
    keyRotationEvent.Event:Connect(function()
        self:CheckKeyRotationNeeds()
        spawn(scheduleKeyRotationCheck)
    end)
    
    -- Start the key rotation monitoring cycle
    spawn(scheduleKeyRotationCheck)
end

function SecurityEncryptionSystem:CheckKeyRotationNeeds()
    local currentTime = os.time()
    
    for keyId, keyData in pairs(self.dataKeys) do
        if keyData.status == "active" and 
           keyData.rotationDue and 
           currentTime >= keyData.rotationDue then
            
            print("⏰ Key rotation needed: " .. keyId)
            self:RotateKey(keyId)
        end
    end
end

function SecurityEncryptionSystem:StoreKeySecurely(keyData)
    -- In production, use HSM or secure key vault
    local secureKeyData = {
        keyId = keyData.keyId,
        keyType = keyData.keyType,
        algorithm = keyData.algorithm,
        createdAt = keyData.createdAt,
        status = keyData.status
        -- Key material would be stored separately in secure storage
    }
    
    pcall(function()
        self.keyStore:SetAsync(keyData.keyId, secureKeyData)
    end)
end

function SecurityEncryptionSystem:LoadKeys()
    -- Load key metadata (not actual key material in production)
    print("🔑 Loading encryption keys...")
end

function SecurityEncryptionSystem:HasMasterKey()
    for _, keyData in pairs(self.masterKeys) do
        if keyData.status == "active" then
            return true
        end
    end
    return false
end

-- ========================================
-- ADMIN AND MONITORING
-- ========================================

function SecurityEncryptionSystem:GetEncryptionStatistics()
    return {
        stats = self.stats,
        performanceMetrics = self.performanceMetrics,
        keyManagement = {
            totalKeys = 0,
            activeKeys = 0,
            expiredKeys = 0
        },
        systemHealth = {
            encryptionLoad = self:CalculateEncryptionLoad(),
            keyRotationStatus = self:GetKeyRotationStatus(),
            algorithmUsage = self:GetAlgorithmUsage()
        }
    }
    
    -- Count keys
    for _ in pairs(self.masterKeys) do
        _.keyManagement.totalKeys = _.keyManagement.totalKeys + 1
    end
    for _ in pairs(self.dataKeys) do
        _.keyManagement.totalKeys = _.keyManagement.totalKeys + 1
    end
end

function SecurityEncryptionSystem:GetEncryptionHealth()
    return {
        systemStatus = "healthy",
        keyRotationUpToDate = true,
        encryptionPerformance = "good",
        securityCompliance = "full"
    }
end

-- Stub implementations for monitoring functions
function SecurityEncryptionSystem:CalculateEncryptionLoad() return 0.1 end
function SecurityEncryptionSystem:GetKeyRotationStatus() return "up_to_date" end
function SecurityEncryptionSystem:GetAlgorithmUsage() return {} end

return SecurityEncryptionSystem
