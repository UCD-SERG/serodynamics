#!/bin/bash
# Test script to verify MCP configuration
set -e
set -u
set -o pipefail

echo "🔍 Verifying MCP Configuration..."
echo ""

# Check if Node.js is installed
echo "1. Checking Node.js installation..."
if command -v node &> /dev/null; then
    echo "   ✅ Node.js found: $(node --version)"
    echo "   ✅ npm found: $(npm --version)"
else
    echo "   ❌ Node.js not found. Please install Node.js to use MCP servers."
    exit 1
fi

# Check if MCP config file exists
echo ""
echo "2. Checking MCP configuration file..."
if [ -f ".github/mcp/mcp-config.json" ]; then
    echo "   ✅ MCP config file found"
    
    # Validate JSON syntax
    if python3 -m json.tool .github/mcp/mcp-config.json > /dev/null 2>&1; then
        echo "   ✅ MCP config JSON is valid"
    else
        echo "   ❌ MCP config JSON is invalid"
        exit 1
    fi
else
    echo "   ❌ MCP config file not found"
    exit 1
fi

# Check environment variables
echo ""
echo "3. Checking environment variables..."
if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "   ✅ GITHUB_TOKEN is set"
else
    echo "   ⚠️  GITHUB_TOKEN is not set (optional for some MCP features)"
fi

if [ -n "${BRAVE_API_KEY:-}" ]; then
    echo "   ✅ BRAVE_API_KEY is set"
else
    echo "   ⚠️  BRAVE_API_KEY is not set (optional for web search)"
fi

# Test if we can install MCP servers (dry run)
echo ""
echo "4. Testing MCP server availability..."

servers=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-git"
)

for server in "${servers[@]}"; do
    echo -n "   Testing $server... "
    if npm view "$server" version &> /dev/null; then
        echo "✅"
    else
        echo "❌ (not available or network issue)"
    fi
done

echo ""
echo "5. Checking development environment files..."

files=(
    ".vscode/settings.json"
    ".vscode/extensions.json"
    ".vscode/tasks.json"
    ".devcontainer/devcontainer.json"
    ".devcontainer/setup.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file found"
    else
        echo "   ❌ $file not found"
    fi
done

echo ""
echo "✨ MCP configuration verification complete!"
echo ""
echo "To use MCP servers:"
echo "  1. Ensure Node.js is installed"
echo "  2. Set GITHUB_TOKEN environment variable for GitHub integration"
echo "  3. Open repository in VS Code with GitHub Copilot extension"
echo "  4. MCP servers will be automatically available to Copilot"
echo ""
echo "See .github/mcp/README.md for detailed setup instructions."
