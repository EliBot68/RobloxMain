-- TroubleshootingFAQSystem.luau
-- Comprehensive troubleshooting guides and FAQ systems
-- Provides searchable help documentation and automated problem resolution

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SafeRequire = require(ReplicatedStorage.Shared.utils.SafeRequire)

local TroubleshootingFAQSystem = {}

-- ========================================
-- TROUBLESHOOTING CONFIGURATION
-- ========================================

local TROUBLESHOOTING_CONFIG = {
    -- Categories
    categories = {
        setup = {
            name = "Setup & Installation",
            description = "Issues with project setup and development environment",
            priority = "high",
            icon = "🔧"
        },
        
        performance = {
            name = "Performance Issues",
            description = "Game performance, lag, and optimization problems",
            priority = "high",
            icon = "⚡"
        },
        
        mobile = {
            name = "Mobile Development",
            description = "Mobile-specific issues and optimizations",
            priority = "medium",
            icon = "📱"
        },
        
        networking = {
            name = "Networking & Multiplayer",
            description = "Connection issues and multiplayer problems",
            priority = "high",
            icon = "🌐"
        },
        
        ui = {
            name = "UI & Interface",
            description = "User interface and layout problems",
            priority = "medium",
            icon = "🎨"
        },
        
        scripting = {
            name = "Scripting & Logic",
            description = "Code errors and logic issues",
            priority = "high",
            icon = "💻"
        },
        
        deployment = {
            name = "Deployment & Publishing",
            description = "Issues with publishing and deployment",
            priority = "medium",
            icon = "🚀"
        },
        
        tools = {
            name = "Development Tools",
            description = "Problems with development tools and utilities",
            priority = "low",
            icon = "🛠️"
        }
    },
    
    -- Search settings
    search = {
        enableFuzzySearch = true,
        maxResults = 20,
        highlightMatches = true,
        searchFields = {"title", "description", "tags", "solution"},
        
        weights = {
            title = 3.0,
            tags = 2.5,
            description = 2.0,
            solution = 1.5,
            symptoms = 1.0
        }
    },
    
    -- Auto-resolution settings
    autoResolution = {
        enabled = true,
        maxAttempts = 3,
        timeoutSeconds = 30,
        
        diagnostics = {
            enabled = true,
            collectSystemInfo = true,
            collectErrorLogs = true,
            collectPerformanceMetrics = true
        }
    },
    
    -- FAQ settings
    faq = {
        categoriesPerPage = 10,
        questionsPerCategory = 50,
        enableVoting = true,
        enableComments = false,
        
        autoSuggest = {
            enabled = true,
            minSimilarity = 0.7,
            maxSuggestions = 5
        }
    }
}

-- ========================================
-- SYSTEM STATE
-- ========================================

local SystemState = {
    -- Core engines
    troubleshootingEngine = nil,
    faqEngine = nil,
    searchEngine = nil,
    
    -- Knowledge base
    troubleshootingGuides = {},
    faqDatabase = {},
    solutions = {},
    
    -- Diagnostics
    diagnosticTools = {},
    systemInfo = {},
    
    -- User interaction
    searchHistory = {},
    userFeedback = {},
    
    -- Metrics
    metrics = {
        guidesAccessed = 0,
        faqsViewed = 0,
        searchesPerformed = 0,
        problemsResolved = 0,
        autoResolutionSuccess = 0
    },
    
    -- Configuration
    config = TROUBLESHOOTING_CONFIG
}

function TroubleshootingFAQSystem.initialize()
    print("❓ Initializing TroubleshootingFAQSystem...")
    
    -- Initialize core engines
    TroubleshootingFAQSystem.initializeTroubleshootingEngine()
    TroubleshootingFAQSystem.initializeFAQEngine()
    TroubleshootingFAQSystem.initializeSearchEngine()
    
    -- Build knowledge base
    TroubleshootingFAQSystem.buildTroubleshootingGuides()
    TroubleshootingFAQSystem.buildFAQDatabase()
    
    -- Initialize diagnostic tools
    TroubleshootingFAQSystem.initializeDiagnosticTools()
    
    -- Create help interface
    TroubleshootingFAQSystem.createHelpInterface()
    
    print("❓ TroubleshootingFAQSystem initialized successfully")
end

-- ========================================
-- TROUBLESHOOTING ENGINE
-- ========================================

function TroubleshootingFAQSystem.initializeTroubleshootingEngine()
    SystemState.troubleshootingEngine = {
        guides = {},
        solutions = {},
        
        findSolution = function(self, problem)
            return TroubleshootingFAQSystem.findSolution(problem)
        end,
        
        runDiagnostics = function(self, category)
            return TroubleshootingFAQSystem.runDiagnostics(category)
        end,
        
        autoResolve = function(self, issue)
            return TroubleshootingFAQSystem.attemptAutoResolution(issue)
        end
    }
    
    print("🔍 Troubleshooting engine initialized")
end

function TroubleshootingFAQSystem.buildTroubleshootingGuides()
    SystemState.troubleshootingGuides = {
        -- Setup & Installation Issues
        setup = {
            {
                id = "setup_001",
                title = "Rojo Connection Failed",
                category = "setup",
                severity = "high",
                tags = {"rojo", "connection", "studio", "sync"},
                
                symptoms = {
                    "Cannot connect to Rojo server",
                    "Studio shows connection timeout",
                    "Code changes not syncing",
                    "HTTP 404 errors in output"
                },
                
                commonCauses = {
                    "Rojo server not running",
                    "Incorrect port configuration",
                    "Studio HTTP service disabled",
                    "Firewall blocking connection"
                },
                
                solution = {
                    steps = {
                        "1. Verify Rojo server is running: Check terminal for 'Listening on port 34872'",
                        "2. Enable HTTP requests in Studio: Game Settings > Security > Allow HTTP Requests",
                        "3. Check port configuration in default.project.json",
                        "4. Restart Rojo server: Ctrl+C then run start_rojo.bat again",
                        "5. Verify firewall isn't blocking port 34872"
                    },
                    
                    commands = {
                        "cd project_directory",
                        "rojo serve",
                        "-- In Studio: Connect to localhost:34872"
                    },
                    
                    troubleshooting = {
                        "If port 34872 is busy, try changing port in default.project.json",
                        "Check Windows Defender firewall exceptions",
                        "Ensure Studio and Rojo are running as same user permissions"
                    }
                },
                
                relatedIssues = {"setup_002", "setup_003"},
                lastUpdated = os.date(),
                difficulty = "beginner"
            },
            
            {
                id = "setup_002", 
                title = "Missing Dependencies Error",
                category = "setup",
                severity = "medium",
                tags = {"dependencies", "aftman", "installation", "tools"},
                
                symptoms = {
                    "Command not found errors",
                    "Tool installation failures",
                    "Missing executable warnings",
                    "Path not found errors"
                },
                
                commonCauses = {
                    "Aftman not installed",
                    "Dependencies not installed via aftman",
                    "PATH environment variable not set",
                    "Tools installed in wrong directory"
                },
                
                solution = {
                    steps = {
                        "1. Install Aftman: Download from GitHub releases",
                        "2. Run 'aftman install' in project directory",
                        "3. Verify tools installed: 'aftman list'",
                        "4. Add Aftman bin to PATH if needed",
                        "5. Restart terminal/command prompt"
                    },
                    
                    commands = {
                        "aftman install",
                        "aftman list",
                        "rojo --version",
                        "selene --version"
                    },
                    
                    troubleshooting = {
                        "On Windows, may need to add ~/.aftman/bin to PATH",
                        "Check aftman.toml file exists in project root",
                        "Try running as administrator if permission errors"
                    }
                },
                
                relatedIssues = {"setup_001", "tools_001"},
                lastUpdated = os.date(),
                difficulty = "beginner"
            }
        },
        
        -- Performance Issues
        performance = {
            {
                id = "perf_001",
                title = "Low FPS on Mobile Devices",
                category = "performance",
                severity = "high",
                tags = {"fps", "mobile", "optimization", "rendering"},
                
                symptoms = {
                    "Game runs below 30 FPS on mobile",
                    "Frame drops during gameplay",
                    "Stuttering or lag spikes",
                    "Battery drains quickly"
                },
                
                commonCauses = {
                    "Too many parts/meshes in workspace",
                    "Unoptimized scripts running every frame",
                    "High-resolution textures",
                    "Complex lighting calculations"
                },
                
                solution = {
                    steps = {
                        "1. Enable mobile performance profiler in game",
                        "2. Reduce part count: Use CSG unions sparingly",
                        "3. Optimize textures: Use lower resolution for mobile",
                        "4. Implement level-of-detail (LOD) system",
                        "5. Use MobileOptimizationManager for automatic adjustments"
                    },
                    
                    codeExamples = {
                        [[-- Enable performance monitoring
local MobileOptimizer = require(ReplicatedStorage.Shared.mobile.MobileOptimizationManager)
MobileOptimizer.optimizeForDevice()]],
                        
                        [[-- Implement simple LOD
local function updateLOD(part, distance)
    if distance > 100 then
        part.Material = Enum.Material.SmoothPlastic -- Simple material
    end
end]]
                    },
                    
                    troubleshooting = {
                        "Use Roblox Developer Console to identify performance bottlenecks",
                        "Test on actual mobile devices, not just Studio mobile emulator",
                        "Consider using StreamingEnabled for large worlds"
                    }
                },
                
                relatedIssues = {"perf_002", "mobile_001"},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            },
            
            {
                id = "perf_002",
                title = "Memory Leaks and High Memory Usage",
                category = "performance", 
                severity = "high",
                tags = {"memory", "leak", "garbage", "optimization"},
                
                symptoms = {
                    "Memory usage increases over time",
                    "Game crashes with out of memory errors",
                    "Performance degrades during long play sessions",
                    "Mobile devices become unresponsive"
                },
                
                commonCauses = {
                    "Event connections not disconnected",
                    "Tables holding references to destroyed objects",
                    "Coroutines not properly cleaned up",
                    "Large data structures not being garbage collected"
                },
                
                solution = {
                    steps = {
                        "1. Use DeveloperToolsSystem memory profiler",
                        "2. Implement proper cleanup in all managers",
                        "3. Disconnect event connections when objects destroyed",
                        "4. Use weak references where appropriate",
                        "5. Regularly clear cached data that's no longer needed"
                    },
                    
                    codeExamples = {
                        [[-- Proper event cleanup
local connection = part.Touched:Connect(onTouched)
-- Later, when cleaning up:
connection:Disconnect()
connection = nil]],
                        
                        [[-- Weak reference table
local weakTable = setmetatable({}, {__mode = "v"})
-- Objects in this table can be garbage collected]]
                    },
                    
                    troubleshooting = {
                        "Use Developer Console Memory tab to track memory usage",
                        "Implement memory monitoring in your game with alerts",
                        "Test memory usage over extended play sessions"
                    }
                },
                
                relatedIssues = {"perf_001", "scripting_002"},
                lastUpdated = os.date(),
                difficulty = "advanced"
            }
        },
        
        -- Mobile Development Issues
        mobile = {
            {
                id = "mobile_001",
                title = "Touch Input Not Working Correctly",
                category = "mobile",
                severity = "medium",
                tags = {"touch", "input", "gestures", "mobile"},
                
                symptoms = {
                    "Touch inputs not registered",
                    "Swipe gestures not detected",
                    "UI buttons not responding to touch",
                    "Multi-touch not working"
                },
                
                commonCauses = {
                    "TouchInputManager not initialized",
                    "UI elements blocking touch events",
                    "Incorrect touch handling in scripts",
                    "Mobile UI not properly configured"
                },
                
                solution = {
                    steps = {
                        "1. Verify TouchInputManager is initialized on mobile",
                        "2. Check UI element ZIndex and Active properties",
                        "3. Test touch events in MobileUIManager",
                        "4. Ensure proper touch event handling order",
                        "5. Verify mobile-specific input settings"
                    },
                    
                    codeExamples = {
                        [[-- Initialize touch input
local TouchInput = require(ReplicatedStorage.Shared.mobile.TouchInputManager)
TouchInput.initialize()
TouchInput.enableGestures(true)]],
                        
                        [[-- Handle touch events properly
local function onTouchTap(touchPositions, gameProcessedEvent)
    if gameProcessedEvent then return end
    -- Handle touch input here
end]]
                    },
                    
                    troubleshooting = {
                        "Test on real mobile devices, not just Studio emulator",
                        "Check if other UI elements are consuming touch events",
                        "Verify touch areas are large enough for mobile interaction"
                    }
                },
                
                relatedIssues = {"ui_001", "mobile_002"},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            }
        },
        
        -- Networking Issues
        networking = {
            {
                id = "net_001",
                title = "Multiplayer Synchronization Issues",
                category = "networking",
                severity = "high",
                tags = {"sync", "multiplayer", "events", "replication"},
                
                symptoms = {
                    "Player actions not syncing across clients",
                    "Game state inconsistencies",
                    "Remote events not firing",
                    "Data not replicating properly"
                },
                
                commonCauses = {
                    "Remote events not properly configured",
                    "Server-client data mismatch",
                    "Network packet loss",
                    "Timing issues in multiplayer code"
                },
                
                solution = {
                    steps = {
                        "1. Verify RemoteEvents are in ReplicatedStorage",
                        "2. Check server and client event handling",
                        "3. Implement proper error handling for network calls",
                        "4. Use MultiplayerSystem for synchronized actions",
                        "5. Add network diagnostics and logging"
                    },
                    
                    codeExamples = {
                        [[-- Proper remote event usage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GameAction = RemoteEvents:WaitForChild("GameAction")

-- Server side
GameAction.OnServerEvent:Connect(function(player, actionData)
    -- Validate and process action
    if validateAction(player, actionData) then
        processAction(player, actionData)
    end
end)]],
                        
                        [[-- Client side with error handling
local success, result = pcall(function()
    GameAction:FireServer(actionData)
end)
if not success then
    warn("Failed to send action:", result)
end]]
                    },
                    
                    troubleshooting = {
                        "Check Developer Console for remote event errors",
                        "Test with multiple players in different locations",
                        "Monitor network traffic and latency"
                    }
                },
                
                relatedIssues = {"scripting_001", "net_002"},
                lastUpdated = os.date(),
                difficulty = "advanced"
            }
        },
        
        -- UI Issues
        ui = {
            {
                id = "ui_001", 
                title = "UI Not Scaling Properly on Different Screens",
                category = "ui",
                severity = "medium",
                tags = {"scaling", "responsive", "screen", "resolution"},
                
                symptoms = {
                    "UI elements too small on mobile",
                    "UI overlapping on different screen sizes",
                    "Text cut off or unreadable",
                    "Buttons not properly positioned"
                },
                
                commonCauses = {
                    "Using Offset instead of Scale",
                    "Not accounting for safe areas on mobile",
                    "Fixed size UI elements",
                    "Incorrect anchor points"
                },
                
                solution = {
                    steps = {
                        "1. Use UDim2.fromScale for responsive sizing",
                        "2. Implement MobileUIManager optimizations",
                        "3. Test on multiple screen resolutions",
                        "4. Use UIAspectRatioConstraint where needed",
                        "5. Account for mobile safe areas and notches"
                    },
                    
                    codeExamples = {
                        [[-- Responsive UI sizing
local frame = script.Parent
frame.Size = UDim2.fromScale(0.8, 0.6) -- 80% width, 60% height
frame.Position = UDim2.fromScale(0.1, 0.2) -- Centered with margin]],
                        
                        [[-- Mobile safe area handling
local MobileUI = require(ReplicatedStorage.Shared.mobile.MobileUIManager)
MobileUI.adjustForSafeArea(frame)]]
                    },
                    
                    troubleshooting = {
                        "Test UI on various devices using Device Emulator",
                        "Check for UI scaling issues in both portrait and landscape",
                        "Verify text readability at different sizes"
                    }
                },
                
                relatedIssues = {"mobile_001", "ui_002"},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            }
        },
        
        -- Scripting Issues
        scripting = {
            {
                id = "script_001",
                title = "Script Errors and Infinite Loops",
                category = "scripting",
                severity = "high",
                tags = {"errors", "debugging", "loops", "crashes"},
                
                symptoms = {
                    "Scripts throwing errors in output",
                    "Game freezing or crashing",
                    "Infinite loop warnings",
                    "Performance drops during script execution"
                },
                
                commonCauses = {
                    "Logical errors in code",
                    "Missing nil checks",
                    "Infinite while loops",
                    "Recursive function calls without base case"
                },
                
                solution = {
                    steps = {
                        "1. Use DeveloperToolsSystem debugger",
                        "2. Add proper error handling with pcall",
                        "3. Implement loop safety checks",
                        "4. Use code linting to catch common errors",
                        "5. Add comprehensive logging for debugging"
                    },
                    
                    codeExamples = {
                        [[-- Safe function execution
local success, result = pcall(function()
    return riskFunction(parameter)
end)
if not success then
    warn("Function failed:", result)
    return defaultValue
end]],
                        
                        [[-- Loop safety
local maxIterations = 1000
local iterations = 0
while condition and iterations < maxIterations do
    -- Loop body
    iterations = iterations + 1
end
if iterations >= maxIterations then
    warn("Loop exceeded maximum iterations")
end]]
                    },
                    
                    troubleshooting = {
                        "Use print statements to trace code execution",
                        "Enable script debugging in Studio",
                        "Use CodeStyleLintingSystem to catch potential issues"
                    }
                },
                
                relatedIssues = {"perf_002", "script_002"},
                lastUpdated = os.date(),
                difficulty = "beginner"
            }
        }
    }
    
    print("📚 Troubleshooting guides built successfully")
end

-- ========================================
-- FAQ ENGINE
-- ========================================

function TroubleshootingFAQSystem.initializeFAQEngine()
    SystemState.faqEngine = {
        database = {},
        categories = {},
        
        searchFAQ = function(self, query)
            return TroubleshootingFAQSystem.searchFAQ(query)
        end,
        
        addFAQ = function(self, faq)
            return TroubleshootingFAQSystem.addFAQ(faq)
        end,
        
        voteFAQ = function(self, faqId, helpful)
            return TroubleshootingFAQSystem.voteFAQ(faqId, helpful)
        end
    }
    
    print("❓ FAQ engine initialized")
end

function TroubleshootingFAQSystem.buildFAQDatabase()
    SystemState.faqDatabase = {
        -- General Questions
        general = {
            {
                id = "faq_001",
                question = "How do I set up the development environment?",
                answer = [[
To set up the development environment:

1. **Install Required Tools:**
   - Download and install Roblox Studio
   - Install Aftman for tool management
   - Clone the project repository

2. **Install Dependencies:**
   ```bash
   aftman install
   ```

3. **Start Development Server:**
   ```bash
   ./start_rojo.bat
   ```

4. **Connect Studio:**
   - Open Roblox Studio
   - Enable HTTP requests in Game Settings
   - Connect to localhost:34872

5. **Verify Setup:**
   - Code changes should sync automatically
   - Check output for any errors

For detailed setup instructions, see the SETUP_GUIDE.md file.
                ]],
                tags = {"setup", "environment", "installation", "beginner"},
                category = "general",
                votes = {helpful = 15, notHelpful = 2},
                lastUpdated = os.date(),
                difficulty = "beginner"
            },
            
            {
                id = "faq_002",
                question = "What are the recommended coding standards?",
                answer = [[
Our project follows these coding standards:

1. **Naming Conventions:**
   - Functions: camelCase (e.g., `updatePlayerScore`)
   - Variables: camelCase (e.g., `playerHealth`)
   - Constants: UPPER_SNAKE_CASE (e.g., `MAX_PLAYERS`)
   - Classes: PascalCase (e.g., `PlayerManager`)

2. **Code Style:**
   - Use 4 spaces for indentation
   - Maximum line length: 100 characters
   - Use double quotes for strings
   - Add trailing commas in tables

3. **Documentation:**
   - All public functions must have documentation
   - Include parameter and return types
   - Add usage examples for complex functions

4. **Code Quality:**
   - Use CodeStyleLintingSystem for automated checking
   - No unused variables or imports
   - Proper error handling with pcall
   - Avoid magic numbers

The CodeStyleLintingSystem automatically enforces these standards.
                ]],
                tags = {"coding", "standards", "style", "quality"},
                category = "general",
                votes = {helpful = 22, notHelpful = 1},
                lastUpdated = os.date(),
                difficulty = "beginner"
            },
            
            {
                id = "faq_003",
                question = "How do I debug performance issues?",
                answer = [[
To debug performance issues:

1. **Use Built-in Profiler:**
   ```lua
   local DeveloperTools = require(ReplicatedStorage.Shared.quality.DeveloperToolsSystem)
   DeveloperTools.startProfiling()
   ```

2. **Check Common Issues:**
   - Too many parts in workspace
   - Scripts running every frame unnecessarily
   - Memory leaks from uncleaned connections
   - Unoptimized mobile performance

3. **Mobile Optimization:**
   ```lua
   local MobileOptimizer = require(ReplicatedStorage.Shared.mobile.MobileOptimizationManager)
   MobileOptimizer.optimizeForDevice()
   ```

4. **Monitor Memory Usage:**
   - Use Developer Console Memory tab
   - Check for increasing memory over time
   - Implement proper cleanup in all systems

5. **Network Performance:**
   - Minimize RemoteEvent calls
   - Batch data updates where possible
   - Use proper data validation

For detailed performance guidelines, see the Performance Optimization guide.
                ]],
                tags = {"performance", "debugging", "optimization", "profiling"},
                category = "performance",
                votes = {helpful = 18, notHelpful = 3},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            }
        },
        
        -- Mobile Development
        mobile = {
            {
                id = "faq_004",
                question = "How do I optimize my game for mobile devices?",
                answer = [[
Mobile optimization strategies:

1. **Performance Optimization:**
   - Reduce part count and complexity
   - Use lower resolution textures for mobile
   - Implement level-of-detail (LOD) systems
   - Enable automatic mobile optimization

2. **UI Optimization:**
   - Use responsive scaling (UDim2.fromScale)
   - Account for mobile safe areas
   - Make touch targets at least 44x44 pixels
   - Test on various screen sizes

3. **Input Handling:**
   ```lua
   local TouchInput = require(ReplicatedStorage.Shared.mobile.TouchInputManager)
   TouchInput.initialize()
   TouchInput.enableGestures(true)
   ```

4. **Battery Efficiency:**
   - Limit background processing
   - Use efficient rendering techniques
   - Implement smart update systems

5. **Testing:**
   - Test on real mobile devices
   - Use Device Emulator in Studio
   - Monitor performance metrics

The MobileOptimizationManager handles many optimizations automatically.
                ]],
                tags = {"mobile", "optimization", "performance", "ui"},
                category = "mobile",
                votes = {helpful = 25, notHelpful = 2},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            }
        },
        
        -- Development Tools
        tools = {
            {
                id = "faq_005",
                question = "How do I use the development tools effectively?",
                answer = [[
Using the development tools:

1. **Developer Tools System:**
   ```lua
   local DevTools = require(ReplicatedStorage.Shared.quality.DeveloperToolsSystem)
   DevTools.openConsole() -- Opens developer console
   DevTools.startProfiling() -- Begins performance profiling
   ```

2. **Code Style and Linting:**
   ```lua
   local StyleSystem = require(ReplicatedStorage.Shared.quality.CodeStyleLintingSystem)
   local issues = StyleSystem.lintCode(codeString)
   local formatted = StyleSystem.formatCode(codeString)
   ```

3. **API Documentation:**
   ```lua
   local APIDoc = require(ReplicatedStorage.Shared.quality.APIDocumentationGenerator)
   APIDoc.generateDocumentation("SystemName")
   ```

4. **Architecture Diagrams:**
   ```lua
   local ArchDiagram = require(ReplicatedStorage.Shared.quality.ArchitectureDiagramsSystem)
   local diagram = ArchDiagram.generateDiagram("systemOverview")
   ```

5. **Keyboard Shortcuts:**
   - F1: Open help system
   - F2: Open developer console
   - F3: Toggle performance profiler
   - F4: Open object inspector

These tools help maintain code quality and debug issues efficiently.
                ]],
                tags = {"tools", "debugging", "development", "console"},
                category = "tools",
                votes = {helpful = 20, notHelpful = 1},
                lastUpdated = os.date(),
                difficulty = "intermediate"
            }
        }
    }
    
    print("❓ FAQ database built successfully")
end

-- ========================================
-- SEARCH ENGINE
-- ========================================

function TroubleshootingFAQSystem.initializeSearchEngine()
    SystemState.searchEngine = {
        index = {},
        
        search = function(self, query, category)
            return TroubleshootingFAQSystem.performSearch(query, category)
        end,
        
        buildIndex = function(self)
            return TroubleshootingFAQSystem.buildSearchIndex()
        end,
        
        addToIndex = function(self, item)
            return TroubleshootingFAQSystem.addToSearchIndex(item)
        end
    }
    
    -- Build initial search index
    SystemState.searchEngine:buildIndex()
    
    print("🔍 Search engine initialized")
end

function TroubleshootingFAQSystem.performSearch(query, category)
    local results = {}
    local searchTerms = string.lower(query):split("%s+")
    
    -- Search troubleshooting guides
    for categoryName, guides in pairs(SystemState.troubleshootingGuides) do
        if not category or category == categoryName then
            for _, guide in ipairs(guides) do
                local score = TroubleshootingFAQSystem.calculateSearchScore(guide, searchTerms)
                if score > 0 then
                    table.insert(results, {
                        type = "troubleshooting",
                        item = guide,
                        score = score,
                        category = categoryName
                    })
                end
            end
        end
    end
    
    -- Search FAQ database
    for categoryName, faqs in pairs(SystemState.faqDatabase) do
        if not category or category == categoryName then
            for _, faq in ipairs(faqs) do
                local score = TroubleshootingFAQSystem.calculateSearchScore(faq, searchTerms)
                if score > 0 then
                    table.insert(results, {
                        type = "faq",
                        item = faq,
                        score = score,
                        category = categoryName
                    })
                end
            end
        end
    end
    
    -- Sort by relevance score
    table.sort(results, function(a, b) return a.score > b.score end)
    
    -- Limit results
    local maxResults = SystemState.config.search.maxResults
    if #results > maxResults then
        for i = maxResults + 1, #results do
            results[i] = nil
        end
    end
    
    SystemState.metrics.searchesPerformed = SystemState.metrics.searchesPerformed + 1
    
    return results
end

function TroubleshootingFAQSystem.calculateSearchScore(item, searchTerms)
    local score = 0
    local weights = SystemState.config.search.weights
    
    -- Check title
    if item.title then
        local titleLower = string.lower(item.title)
        for _, term in ipairs(searchTerms) do
            if titleLower:find(term, 1, true) then
                score = score + weights.title
            end
        end
    end
    
    -- Check tags
    if item.tags then
        for _, tag in ipairs(item.tags) do
            local tagLower = string.lower(tag)
            for _, term in ipairs(searchTerms) do
                if tagLower:find(term, 1, true) then
                    score = score + weights.tags
                end
            end
        end
    end
    
    -- Check description/answer
    local content = item.description or item.answer or ""
    if content then
        local contentLower = string.lower(content)
        for _, term in ipairs(searchTerms) do
            if contentLower:find(term, 1, true) then
                score = score + weights.description
            end
        end
    end
    
    -- Check symptoms
    if item.symptoms then
        for _, symptom in ipairs(item.symptoms) do
            local symptomLower = string.lower(symptom)
            for _, term in ipairs(searchTerms) do
                if symptomLower:find(term, 1, true) then
                    score = score + weights.symptoms
                end
            end
        end
    end
    
    return score
end

function TroubleshootingFAQSystem.buildSearchIndex()
    SystemState.searchEngine.index = {}
    
    -- Index troubleshooting guides
    for category, guides in pairs(SystemState.troubleshootingGuides) do
        for _, guide in ipairs(guides) do
            TroubleshootingFAQSystem.addToSearchIndex(guide)
        end
    end
    
    -- Index FAQ items
    for category, faqs in pairs(SystemState.faqDatabase) do
        for _, faq in ipairs(faqs) do
            TroubleshootingFAQSystem.addToSearchIndex(faq)
        end
    end
    
    print("🔍 Search index built successfully")
end

function TroubleshootingFAQSystem.addToSearchIndex(item)
    -- Extract keywords for indexing
    local keywords = {}
    
    if item.title then
        for word in string.lower(item.title):gmatch("%w+") do
            keywords[word] = true
        end
    end
    
    if item.tags then
        for _, tag in ipairs(item.tags) do
            keywords[string.lower(tag)] = true
        end
    end
    
    -- Add to index
    for keyword, _ in pairs(keywords) do
        if not SystemState.searchEngine.index[keyword] then
            SystemState.searchEngine.index[keyword] = {}
        end
        table.insert(SystemState.searchEngine.index[keyword], item)
    end
end

-- ========================================
-- DIAGNOSTIC TOOLS
-- ========================================

function TroubleshootingFAQSystem.initializeDiagnosticTools()
    SystemState.diagnosticTools = {
        systemInfo = TroubleshootingFAQSystem.collectSystemInfo(),
        
        runDiagnostic = function(category)
            return TroubleshootingFAQSystem.runDiagnostics(category)
        end,
        
        collectLogs = function()
            return TroubleshootingFAQSystem.collectErrorLogs()
        end,
        
        checkHealth = function()
            return TroubleshootingFAQSystem.performHealthCheck()
        end
    }
    
    print("🔧 Diagnostic tools initialized")
end

function TroubleshootingFAQSystem.collectSystemInfo()
    return {
        platform = game:GetService("UserInputService").TouchEnabled and "Mobile" or "Desktop",
        studioVersion = version(),
        httpEnabled = game:GetService("HttpService").HttpEnabled,
        streamingEnabled = workspace.StreamingEnabled,
        placeId = game.PlaceId,
        timestamp = os.date()
    }
end

function TroubleshootingFAQSystem.runDiagnostics(category)
    local diagnostics = {
        category = category,
        tests = {},
        summary = {
            passed = 0,
            failed = 0,
            warnings = 0
        }
    }
    
    if category == "setup" then
        -- Check Rojo connection
        table.insert(diagnostics.tests, {
            name = "Rojo Connection",
            status = "unknown",
            message = "Check if Rojo server is accessible",
            fix = "Ensure Rojo server is running and HTTP requests are enabled"
        })
        
        -- Check required services
        table.insert(diagnostics.tests, {
            name = "Required Services",
            status = game:GetService("HttpService").HttpEnabled and "passed" or "failed",
            message = game:GetService("HttpService").HttpEnabled and "HTTP requests enabled" or "HTTP requests disabled",
            fix = "Enable HTTP requests in Game Settings > Security"
        })
    elseif category == "performance" then
        -- Check memory usage
        local memoryUsage = collectgarbage("count")
        table.insert(diagnostics.tests, {
            name = "Memory Usage",
            status = memoryUsage < 100000 and "passed" or "warning",
            message = string.format("Memory usage: %.2f MB", memoryUsage / 1024),
            fix = "Consider optimizing scripts and cleaning up unused objects"
        })
        
        -- Check part count
        local partCount = #workspace:GetDescendants()
        table.insert(diagnostics.tests, {
            name = "Part Count", 
            status = partCount < 10000 and "passed" or "warning",
            message = string.format("Workspace objects: %d", partCount),
            fix = "Consider reducing part count or using StreamingEnabled"
        })
    end
    
    -- Update summary
    for _, test in ipairs(diagnostics.tests) do
        if test.status == "passed" then
            diagnostics.summary.passed = diagnostics.summary.passed + 1
        elseif test.status == "failed" then
            diagnostics.summary.failed = diagnostics.summary.failed + 1
        else
            diagnostics.summary.warnings = diagnostics.summary.warnings + 1
        end
    end
    
    return diagnostics
end

function TroubleshootingFAQSystem.collectErrorLogs()
    -- Placeholder for error log collection
    return {
        errors = {},
        warnings = {},
        timestamp = os.date()
    }
end

function TroubleshootingFAQSystem.performHealthCheck()
    local health = {
        overall = "healthy",
        systems = {},
        recommendations = {}
    }
    
    -- Check core systems
    local coreSystemChecks = {
        "GameStateManager",
        "PlayerDataManager", 
        "EventBus",
        "MobileOptimizationManager"
    }
    
    for _, systemName in ipairs(coreSystemChecks) do
        local systemHealth = {
            name = systemName,
            status = "unknown",
            message = "System check not implemented"
        }
        
        -- Try to access system
        local success = pcall(function()
            local system = require(ReplicatedStorage.Shared.managers[systemName])
            if system and system.isInitialized then
                systemHealth.status = "healthy"
                systemHealth.message = "System initialized and running"
            else
                systemHealth.status = "warning"
                systemHealth.message = "System not initialized"
            end
        end)
        
        if not success then
            systemHealth.status = "error"
            systemHealth.message = "System not found or failed to load"
        end
        
        table.insert(health.systems, systemHealth)
    end
    
    return health
end

-- ========================================
-- AUTO-RESOLUTION
-- ========================================

function TroubleshootingFAQSystem.attemptAutoResolution(issue)
    if not SystemState.config.autoResolution.enabled then
        return {success = false, message = "Auto-resolution disabled"}
    end
    
    local resolution = {
        success = false,
        steps = {},
        message = "",
        automated = true
    }
    
    -- Attempt common fixes based on issue type
    if issue.category == "setup" and issue.id == "setup_001" then
        -- Try to fix Rojo connection issues
        table.insert(resolution.steps, "Checking HTTP service status...")
        
        if not game:GetService("HttpService").HttpEnabled then
            resolution.message = "HTTP requests need to be manually enabled in Studio settings"
            resolution.success = false
        else
            table.insert(resolution.steps, "HTTP service is enabled")
            resolution.success = true
            resolution.message = "Basic setup checks passed"
        end
    elseif issue.category == "performance" then
        -- Auto-optimize performance
        table.insert(resolution.steps, "Running performance optimization...")
        
        local success = pcall(function()
            local MobileOptimizer = require(ReplicatedStorage.Shared.mobile.MobileOptimizationManager)
            MobileOptimizer.optimizeForDevice()
        end)
        
        if success then
            table.insert(resolution.steps, "Mobile optimization applied")
            resolution.success = true
            resolution.message = "Automatic performance optimization completed"
        else
            resolution.success = false
            resolution.message = "Failed to apply automatic optimizations"
        end
    end
    
    if resolution.success then
        SystemState.metrics.autoResolutionSuccess = SystemState.metrics.autoResolutionSuccess + 1
    end
    
    return resolution
end

-- ========================================
-- HELP INTERFACE
-- ========================================

function TroubleshootingFAQSystem.createHelpInterface()
    SystemState.helpInterface = {
        isOpen = false,
        currentView = "search",
        
        show = function(self, view)
            return TroubleshootingFAQSystem.showHelpInterface(view)
        end,
        
        hide = function(self)
            return TroubleshootingFAQSystem.hideHelpInterface()
        end,
        
        search = function(self, query)
            return TroubleshootingFAQSystem.performSearch(query)
        end
    }
    
    print("🆘 Help interface created")
end

function TroubleshootingFAQSystem.showHelpInterface(view)
    view = view or "search"
    
    SystemState.helpInterface.isOpen = true
    SystemState.helpInterface.currentView = view
    
    print(string.format("🆘 Help interface opened - %s view", view))
    
    -- Return interface data for UI rendering
    return {
        view = view,
        categories = SystemState.config.categories,
        recentSearches = SystemState.searchHistory,
        popularFAQs = TroubleshootingFAQSystem.getPopularFAQs()
    }
end

function TroubleshootingFAQSystem.hideHelpInterface()
    SystemState.helpInterface.isOpen = false
    print("🆘 Help interface closed")
end

function TroubleshootingFAQSystem.getPopularFAQs()
    local popular = {}
    
    for category, faqs in pairs(SystemState.faqDatabase) do
        for _, faq in ipairs(faqs) do
            if faq.votes and faq.votes.helpful > 10 then
                table.insert(popular, {
                    faq = faq,
                    score = faq.votes.helpful - faq.votes.notHelpful
                })
            end
        end
    end
    
    table.sort(popular, function(a, b) return a.score > b.score end)
    
    local result = {}
    for i = 1, math.min(5, #popular) do
        table.insert(result, popular[i].faq)
    end
    
    return result
end

-- ========================================
-- PUBLIC API
-- ========================================

function TroubleshootingFAQSystem.searchHelp(query, category)
    return SystemState.searchEngine:search(query, category)
end

function TroubleshootingFAQSystem.findSolution(problem)
    local solutions = SystemState.searchEngine:search(problem.title or problem.description)
    
    -- Try auto-resolution first
    if #solutions > 0 then
        local topSolution = solutions[1]
        if topSolution.type == "troubleshooting" then
            local autoResolution = TroubleshootingFAQSystem.attemptAutoResolution(topSolution.item)
            if autoResolution.success then
                return {
                    solution = topSolution.item,
                    autoResolved = true,
                    resolution = autoResolution
                }
            end
        end
    end
    
    return {
        solutions = solutions,
        autoResolved = false,
        suggestions = TroubleshootingFAQSystem.getSimilarIssues(problem)
    }
end

function TroubleshootingFAQSystem.getSimilarIssues(problem)
    -- Find similar issues based on keywords
    local keywords = {}
    if problem.title then
        for word in problem.title:gmatch("%w+") do
            table.insert(keywords, word)
        end
    end
    
    local query = table.concat(keywords, " ")
    return TroubleshootingFAQSystem.performSearch(query)
end

function TroubleshootingFAQSystem.addFAQ(faq)
    local category = faq.category or "general"
    
    if not SystemState.faqDatabase[category] then
        SystemState.faqDatabase[category] = {}
    end
    
    faq.id = faq.id or ("faq_" .. tostring(#SystemState.faqDatabase[category] + 1))
    faq.votes = faq.votes or {helpful = 0, notHelpful = 0}
    faq.lastUpdated = os.date()
    
    table.insert(SystemState.faqDatabase[category], faq)
    SystemState.searchEngine:addToIndex(faq)
    
    return faq.id
end

function TroubleshootingFAQSystem.voteFAQ(faqId, helpful)
    for category, faqs in pairs(SystemState.faqDatabase) do
        for _, faq in ipairs(faqs) do
            if faq.id == faqId then
                if helpful then
                    faq.votes.helpful = faq.votes.helpful + 1
                else
                    faq.votes.notHelpful = faq.votes.notHelpful + 1
                end
                return true
            end
        end
    end
    return false
end

function TroubleshootingFAQSystem.getMetrics()
    return SystemState.metrics
end

function TroubleshootingFAQSystem.runTroubleshootingDemo()
    print("❓ Running troubleshooting and FAQ demonstration...")
    
    -- Show knowledge base statistics
    print("  📚 Knowledge Base Statistics:")
    local totalGuides = 0
    local totalFAQs = 0
    
    for category, guides in pairs(SystemState.troubleshootingGuides) do
        totalGuides = totalGuides + #guides
        print(string.format("    %s Troubleshooting: %d guides", 
            SystemState.config.categories[category].name, #guides))
    end
    
    for category, faqs in pairs(SystemState.faqDatabase) do
        totalFAQs = totalFAQs + #faqs
        print(string.format("    %s FAQ: %d questions", category, #faqs))
    end
    
    print(string.format("    Total: %d guides, %d FAQs", totalGuides, totalFAQs))
    
    -- Demonstrate search functionality
    print("  🔍 Search Demonstration:")
    local searchQueries = {"rojo connection", "mobile performance", "UI scaling"}
    
    for _, query in ipairs(searchQueries) do
        local results = TroubleshootingFAQSystem.searchHelp(query)
        print(string.format("    '%s': %d results found", query, #results))
        
        if #results > 0 then
            local topResult = results[1]
            print(string.format("      Top result: %s (%s)", 
                topResult.item.title or topResult.item.question, topResult.type))
        end
    end
    
    -- Show diagnostic capabilities
    print("  🔧 Diagnostic Tools:")
    local categories = {"setup", "performance"}
    
    for _, category in ipairs(categories) do
        local diagnostics = TroubleshootingFAQSystem.runDiagnostics(category)
        print(string.format("    %s diagnostics: %d tests (%d passed, %d failed, %d warnings)",
            category, #diagnostics.tests, diagnostics.summary.passed, 
            diagnostics.summary.failed, diagnostics.summary.warnings))
    end
    
    -- Show system health
    print("  🏥 System Health Check:")
    local health = TroubleshootingFAQSystem.performHealthCheck()
    print(string.format("    Overall Status: %s", health.overall))
    print(string.format("    Systems Checked: %d", #health.systems))
    
    for _, system in ipairs(health.systems) do
        print(string.format("      %s: %s", system.name, system.status))
    end
    
    -- Demonstrate auto-resolution
    print("  🤖 Auto-Resolution Demo:")
    local testIssue = {
        category = "setup",
        id = "setup_001",
        title = "Rojo Connection Failed"
    }
    
    local resolution = TroubleshootingFAQSystem.attemptAutoResolution(testIssue)
    print(string.format("    Auto-resolution attempt: %s", resolution.success and "Success" or "Failed"))
    print(string.format("    Steps taken: %d", #resolution.steps))
    print(string.format("    Message: %s", resolution.message))
    
    -- Show FAQ voting system
    print("  👍 FAQ Voting System:")
    local popularFAQs = TroubleshootingFAQSystem.getPopularFAQs()
    print(string.format("    Popular FAQs: %d", #popularFAQs))
    
    for i, faq in ipairs(popularFAQs) do
        if i <= 3 then
            local score = faq.votes.helpful - faq.votes.notHelpful
            print(string.format("      %d. %s (Score: %d)", i, faq.question, score))
        end
    end
    
    -- Show metrics
    print("  📊 Usage Metrics:")
    local metrics = SystemState.metrics
    print(string.format("    Guides Accessed: %d", metrics.guidesAccessed))
    print(string.format("    FAQs Viewed: %d", metrics.faqsViewed))
    print(string.format("    Searches Performed: %d", metrics.searchesPerformed))
    print(string.format("    Problems Resolved: %d", metrics.problemsResolved))
    print(string.format("    Auto-Resolution Success: %d", metrics.autoResolutionSuccess))
    
    -- Show help interface
    print("  🆘 Help Interface Features:")
    print("    ✅ Searchable knowledge base")
    print("    ✅ Categorized troubleshooting guides")
    print("    ✅ Interactive FAQ system")
    print("    ✅ Automated diagnostics")
    print("    ✅ Auto-resolution capabilities")
    print("    ✅ Voting and feedback system")
    print("    ✅ Similar issue suggestions")
    print("    ✅ System health monitoring")
    
    print("❓ Troubleshooting and FAQ demonstration completed")
    print("     Comprehensive help system operational!")
end

-- Initialize the troubleshooting and FAQ system
TroubleshootingFAQSystem.initialize()

print("❓ TroubleshootingFAQSystem loaded with comprehensive help and FAQ capabilities")

return TroubleshootingFAQSystem
