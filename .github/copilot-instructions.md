# Copilot Instructions for Color Rush Roblox Game

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview
This is a Color Rush parkour game for Roblox built with modern architecture and comprehensive features.

## Development Guidelines

### Language and Framework
- This project uses **Luau** (Roblox's Lua variant)
- Project structure follows **Rojo** conventions with `src/client`, `src/server`, and `src/shared` directories
- Use **Roblox services** and APIs appropriately

### Code Style
- Follow Roblox Lua coding conventions
- Use PascalCase for functions and variables when appropriate
- Use proper Roblox service patterns (e.g., `game:GetService()`)
- Implement proper error handling with `pcall` and `xpcall`

### Architecture Patterns
- Use the established service architecture pattern
- Client-server communication through RemoteEvents and RemoteFunctions
- Shared modules should be platform-agnostic
- Follow the existing analytics and data persistence patterns

### Key Systems
- **MainGameService**: Core game logic and flow control
- **AnalyticsService**: Player tracking and metrics
- **Color matching mechanics**: Player color must match track segments
- **Mobile optimization**: Touch-friendly controls and UI
- **Professional UI system**: Modern designs with animations

### Best Practices
- Always validate user input on the server
- Use proper memory management techniques
- Implement comprehensive error handling
- Follow mobile-first design principles
- Maintain accessibility features for colorblind players
