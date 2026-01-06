# Model Context Protocol (MCP) Configuration

This directory contains the MCP server configuration for the serodynamics R package development environment.

## What is MCP?

Model Context Protocol (MCP) is an open protocol that enables seamless integration between AI assistants and development tools. It allows AI assistants to interact with your development environment through standardized servers.

## Configured MCP Servers

The `mcp-config.json` file configures the following MCP servers:

### 1. Filesystem Server
- **Purpose**: Provides file system access to the repository
- **Use cases**: Reading/writing files, searching code, managing project structure
- **Scope**: `/home/runner/work/serodynamics/serodynamics`

### 2. GitHub Server
- **Purpose**: Integrates with GitHub for repository operations
- **Use cases**: Issue tracking, pull requests, workflow management, CI/CD status
- **Authentication**: Uses `GITHUB_TOKEN` environment variable

### 3. Git Server
- **Purpose**: Provides Git version control operations
- **Use cases**: Status checks, diff viewing, log inspection, commits, branch management
- **Scope**: Repository at `/home/runner/work/serodynamics/serodynamics`

### 4. Brave Search Server
- **Purpose**: Enables web search capabilities
- **Use cases**: Finding R package documentation, CRAN resources, troubleshooting
- **Authentication**: Uses `BRAVE_API_KEY` environment variable (optional)

## Setup Instructions

### Prerequisites

1. **Node.js**: Required to run the MCP servers via `npx`
   ```bash
   # Check if Node.js is installed
   node --version
   npm --version
   ```

2. **Environment Variables**:
   - `GITHUB_TOKEN`: GitHub Personal Access Token (required for GitHub server)
   - `BRAVE_API_KEY`: Brave Search API key (optional, for web search)

### Using with GitHub Copilot

1. **In VS Code**:
   - Install the latest GitHub Copilot extension
   - The MCP configuration will be automatically detected from `.github/mcp/mcp-config.json`
   - Copilot will use these servers to enhance code suggestions and operations

2. **In JetBrains IDEs**:
   - Install GitHub Copilot plugin
   - Configure MCP servers through the Copilot settings
   - Point to this `mcp-config.json` file

### Using with Claude Desktop

If you want to use these MCP servers with Claude Desktop:

1. Copy the `mcpServers` section from `mcp-config.json`
2. Add it to your Claude Desktop configuration:
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`

3. Update the repository path in the configuration to your local clone path

## Development Workflow Integration

The MCP servers are particularly useful for:

1. **Code Navigation**: Quickly finding and reading R source files
2. **Testing**: Checking test results and coverage
3. **CI/CD**: Monitoring workflow status and debugging failures
4. **Documentation**: Finding R package documentation and CRAN resources
5. **Version Control**: Managing commits, branches, and reviewing changes

## Best Practices

1. **Always check Git status** before making commits using the Git MCP server
2. **Use the GitHub server** to monitor CI/CD workflows and PR status
3. **Leverage filesystem search** to find similar code patterns in the repository
4. **Search the web** for R package documentation when implementing new features

## Troubleshooting

### MCP servers not starting

1. Ensure Node.js is installed and `npx` is available
2. Check that environment variables are set correctly
3. Verify repository paths are correct for your system

### GitHub authentication issues

1. Ensure `GITHUB_TOKEN` is set with appropriate scopes:
   - `repo` (full control of private repositories)
   - `workflow` (update GitHub Action workflows)
   - `read:org` (read org and team membership)

2. Generate a new token at: https://github.com/settings/tokens

### Permission issues

1. Ensure the filesystem server has read/write access to the repository
2. Check that you have the necessary GitHub repository permissions

## References

- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Filesystem Server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem)
- [MCP GitHub Server](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [MCP Git Server](https://github.com/modelcontextprotocol/servers/tree/main/src/git)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
