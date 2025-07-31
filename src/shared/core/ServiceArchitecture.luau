-- ServiceArchitecture.luau
-- Core service architecture interfaces and base classes for the Color Rush codebase
-- Provides standardized inheritance patterns for different service types

local SafeRequire = require(script.Parent.Parent.utils.SafeRequire)
local ServiceBase = SafeRequire.require(script.Parent.Parent.utils.ServiceBase)

local ServiceArchitecture = {}

-- Base Service Interface (for server-side services)
local BaseService = {}
BaseService.__index = BaseService

function BaseService.new(name, version)
    local service = ServiceBase.new(name, {
        Version = version or "1.0.0",
        Type = "BaseService"
    })
    
    -- Add BaseService specific properties
    service.Version = version or "1.0.0"
    service.ServiceType = "BaseService"
    
    return setmetatable(service, BaseService)
end

function BaseService:GetVersion()
    return self.Version
end

function BaseService:GetServiceInfo()
    return {
        Name = self.Name,
        Version = self.Version,
        Type = self.ServiceType,
        State = self.State,
        IsRunning = self.IsRunning
    }
end

-- Controller Interface (for client-side controllers)
local IController = {}
IController.__index = IController

function IController.new(name, config)
    local controller = ServiceBase.new(name, config or {})
    controller.ServiceType = "Controller"
    return setmetatable(controller, IController)
end

-- Domain Service Interface (for business logic services)
local IDomainService = {}
IDomainService.__index = IDomainService

function IDomainService.new(name, config)
    local service = ServiceBase.new(name, config or {})
    service.ServiceType = "DomainService"
    return setmetatable(service, IDomainService)
end

-- Repository Interface (for data access)
local IRepository = {}
IRepository.__index = IRepository

function IRepository.new(name, config)
    local repository = ServiceBase.new(name, config or {})
    repository.ServiceType = "Repository"
    return setmetatable(repository, IRepository)
end

function IRepository:Get(id)
    error("Get method must be implemented by repository")
end

function IRepository:Save(entity)
    error("Save method must be implemented by repository")
end

function IRepository:Delete(id)
    error("Delete method must be implemented by repository")
end

-- Validator Interface
local IValidator = {}
IValidator.__index = IValidator

function IValidator.new(name, config)
    local validator = ServiceBase.new(name, config or {})
    validator.ServiceType = "Validator"
    return setmetatable(validator, IValidator)
end

function IValidator:Validate(data)
    error("Validate method must be implemented by validator")
end

-- Migration Tool Interface
local IMigrationTool = {}
IMigrationTool.__index = IMigrationTool

function IMigrationTool.new(name, config)
    local tool = ServiceBase.new(name, config or {})
    tool.ServiceType = "MigrationTool"
    return setmetatable(tool, IMigrationTool)
end

function IMigrationTool:Migrate(fromVersion, toVersion)
    error("Migrate method must be implemented by migration tool")
end

-- Audit Logger Interface
local IAuditLogger = {}
IAuditLogger.__index = IAuditLogger

function IAuditLogger.new(name, config)
    local logger = ServiceBase.new(name, config or {})
    logger.ServiceType = "AuditLogger"
    return setmetatable(logger, IAuditLogger)
end

function IAuditLogger:LogAction(userId, action, details)
    error("LogAction method must be implemented by audit logger")
end

-- Security Interfaces
local ISecurityAuditLogger = {}
ISecurityAuditLogger.__index = ISecurityAuditLogger

function ISecurityAuditLogger.new(name, config)
    local logger = ServiceBase.new(name, config or {})
    logger.ServiceType = "SecurityAuditLogger"
    return setmetatable(logger, ISecurityAuditLogger)
end

function ISecurityAuditLogger:LogSecurityEvent(event, severity, details)
    error("LogSecurityEvent method must be implemented by security audit logger")
end

local IEncryptionSystem = {}
IEncryptionSystem.__index = IEncryptionSystem

function IEncryptionSystem.new(name, config)
    local system = ServiceBase.new(name, config or {})
    system.ServiceType = "EncryptionSystem"
    return setmetatable(system, IEncryptionSystem)
end

function IEncryptionSystem:Encrypt(data)
    error("Encrypt method must be implemented by encryption system")
end

function IEncryptionSystem:Decrypt(encryptedData)
    error("Decrypt method must be implemented by encryption system")
end

local IIntrusionDetectionSystem = {}
IIntrusionDetectionSystem.__index = IIntrusionDetectionSystem

function IIntrusionDetectionSystem.new(name, config)
    local system = ServiceBase.new(name, config or {})
    system.ServiceType = "IntrusionDetectionSystem"
    return setmetatable(system, IIntrusionDetectionSystem)
end

function IIntrusionDetectionSystem:DetectIntrusion(pattern)
    error("DetectIntrusion method must be implemented by intrusion detection system")
end

local ISessionManager = {}
ISessionManager.__index = ISessionManager

function ISessionManager.new(name, config)
    local manager = ServiceBase.new(name, config or {})
    manager.ServiceType = "SessionManager"
    return setmetatable(manager, ISessionManager)
end

function ISessionManager:CreateSession(userId)
    error("CreateSession method must be implemented by session manager")
end

function ISessionManager:ValidateSession(sessionId)
    error("ValidateSession method must be implemented by session manager")
end

-- Export all interfaces
ServiceArchitecture.BaseService = BaseService
ServiceArchitecture.IController = IController
ServiceArchitecture.IDomainService = IDomainService
ServiceArchitecture.IRepository = IRepository
ServiceArchitecture.IValidator = IValidator
ServiceArchitecture.IMigrationTool = IMigrationTool
ServiceArchitecture.IAuditLogger = IAuditLogger
ServiceArchitecture.ISecurityAuditLogger = ISecurityAuditLogger
ServiceArchitecture.IEncryptionSystem = IEncryptionSystem
ServiceArchitecture.IIntrusionDetectionSystem = IIntrusionDetectionSystem
ServiceArchitecture.ISessionManager = ISessionManager

return ServiceArchitecture
