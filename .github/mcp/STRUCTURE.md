# Development Environment Structure

This document provides a visual overview of the development environment configurations added to the repository.

## Directory Structure

```
serodynamics/
├── .github/
│   ├── copilot-instructions.md         # Enhanced with MCP and dev env sections
│   ├── mcp/
│   │   ├── mcp-config.json            # MCP server configuration
│   │   ├── README.md                  # MCP setup guide
│   │   ├── SUMMARY.md                 # Overview of additions
│   │   ├── STRUCTURE.md               # This file
│   │   └── verify-mcp.sh              # Configuration verification script
│   └── workflows/                      # CI/CD workflows (existing)
│
├── .vscode/
│   ├── settings.json                  # R-specific VS Code settings
│   ├── extensions.json                # Recommended extensions
│   └── tasks.json                     # Quick tasks for R package ops
│
├── .devcontainer/
│   ├── devcontainer.json              # Container specification
│   ├── setup.sh                       # Automated environment setup
│   └── README.md                      # Dev container guide
│
├── DEVELOPMENT.md                      # Comprehensive development guide
├── .Rbuildignore                      # Updated to exclude new configs
└── ... (other repository files)
```

## Configuration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Environment                   │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
  ┌───────────────┐   ┌──────────────┐   ┌──────────────┐
  │  MCP Servers  │   │  VS Code     │   │ Dev Container│
  │  (.github/mcp)│   │  (.vscode)   │   │(.devcontainer)│
  └───────────────┘   └──────────────┘   └──────────────┘
          │                   │                   │
          │                   │                   │
          ▼                   ▼                   ▼
  ┌───────────────┐   ┌──────────────┐   ┌──────────────┐
  │ AI-Enhanced   │   │ Editor       │   │ Containerized│
  │ Development   │   │ Optimization │   │ Environment  │
  └───────────────┘   └──────────────┘   └──────────────┘
```

## MCP Server Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        GitHub Copilot                         │
└──────────────────────────────────────────────────────────────┘
                              │
                              │ Uses MCP Protocol
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                      MCP Configuration                        │
│                   (.github/mcp/mcp-config.json)              │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┬──────────┐
          │                   │                   │          │
          ▼                   ▼                   ▼          ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ Filesystem   │   │   GitHub     │   │     Git      │   │ Brave Search │
  │   Server     │   │   Server     │   │   Server     │   │    Server    │
  └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
          │                   │                   │                 │
          ▼                   ▼                   ▼                 ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ File I/O     │   │ PR/Issues    │   │ Version      │   │ Web Search   │
  │ Code Search  │   │ CI/CD Status │   │ Control      │   │ CRAN Docs    │
  └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
```

## VS Code Integration

```
┌──────────────────────────────────────────────────────────────┐
│                       VS Code Editor                          │
└──────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │  settings    │   │  extensions  │   │    tasks     │
  │    .json     │   │    .json     │   │    .json     │
  └──────────────┘   └──────────────┘   └──────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ R Config     │   │ R Extension  │   │ Quick Tasks  │
  │ Formatting   │   │ GitHub       │   │ - Document   │
  │ File Assoc   │   │ Copilot      │   │ - Test       │
  │ Copilot      │   │ Quarto       │   │ - Check      │
  └──────────────┘   └──────────────┘   └──────────────┘
```

## Dev Container Workflow

```
┌──────────────────────────────────────────────────────────────┐
│               User Opens Repo in VS Code                      │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│        VS Code Detects .devcontainer/devcontainer.json       │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                  Prompt: "Reopen in Container"                │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
          ┌───────────────────┴───────────────────┐
          │                                       │
          ▼                                       ▼
  ┌──────────────┐                       ┌──────────────┐
  │ Pull Base    │                       │  User Says   │
  │ Image        │                       │   "Yes"      │
  │ rocker/      │                       └──────────────┘
  │ tidyverse    │                               │
  └──────────────┘                               │
          │                                       │
          └───────────────────┬───────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────┐
│              Run .devcontainer/setup.sh                       │
│   - Install JAGS                                             │
│   - Install system dependencies                              │
│   - Install Quarto                                           │
│   - Install R packages                                       │
│   - Verify installation                                      │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│          VS Code Opens in Container Environment               │
│   - All dependencies ready                                   │
│   - Extensions installed                                     │
│   - Settings applied                                         │
└──────────────────────────────────────────────────────────────┘
```

## Development Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                      Developer Starts Work                   │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ Dev Container│   │ Local Setup  │   │ Codespaces   │
  │ (Recommended)│   │ (Traditional)│   │ (Cloud)      │
  └──────────────┘   └──────────────┘   └──────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Development Environment Ready              │
│   - R >= 4.1.0 installed                                    │
│   - JAGS 4.3.1 installed                                    │
│   - All dependencies available                              │
│   - VS Code configured                                      │
│   - MCP servers available (with Copilot)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
          ┌───────────────────┼───────────────────┬──────────┐
          │                   │                   │          │
          ▼                   ▼                   ▼          ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ Code with    │   │ Use VS Code  │   │ Use MCP for  │   │ Run Tests    │
  │ AI Assist    │   │ Tasks        │   │ Context      │   │ via Tasks    │
  └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Commit & Push (Standard Git Flow)               │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Files Relationship

```
DEVELOPMENT.md ─────────┐
                        │
.github/                │
  copilot-instructions.md ──┐
  mcp/                  │   │
    mcp-config.json ────┼───┼─── Used by GitHub Copilot
    README.md ──────────┤   │
    verify-mcp.sh ──────┘   │
                            │
.vscode/                    │
  settings.json ────────────┼─── Used by VS Code
  extensions.json ──────────┼─── Suggests extensions
  tasks.json ───────────────┼─── Quick operations
                            │
.devcontainer/              │
  devcontainer.json ────────┼─── Used by VS Code + Docker
  setup.sh ─────────────────┼─── Runs in container
  README.md ────────────────┘
```

## Key Integration Points

1. **GitHub Copilot + MCP**: Copilot reads `.github/mcp/mcp-config.json` and uses configured servers
2. **VS Code + Dev Container**: VS Code reads `.devcontainer/devcontainer.json` and builds container
3. **VS Code + Settings**: VS Code applies `.vscode/settings.json` for R-optimized editing
4. **VS Code + Tasks**: Tasks in `.vscode/tasks.json` provide quick access to R package operations
5. **Container + Setup**: `.devcontainer/setup.sh` runs on container creation to install dependencies
6. **Documentation + Files**: All READMEs and DEVELOPMENT.md guide users to appropriate configurations

## File Dependencies

```
devcontainer.json
  ├── Requires: Docker, VS Code with Dev Containers extension
  ├── Uses: setup.sh (postCreateCommand)
  └── Installs: Extensions from extensions.json

mcp-config.json
  ├── Requires: Node.js, npx
  ├── Optional: GITHUB_TOKEN, BRAVE_API_KEY
  └── Used by: GitHub Copilot, Claude Desktop

settings.json
  ├── Requires: VS Code
  └── Enhances: R development experience

tasks.json
  ├── Requires: VS Code, R installation
  └── Provides: Quick access to devtools functions

setup.sh
  ├── Requires: apt, wget, Rscript
  └── Installs: JAGS, Quarto, R packages, dependencies
```

## Notes

- All JSON files are validated and properly formatted
- Shell scripts are executable and syntax-checked
- Configurations are platform-aware (Linux/macOS/Windows)
- MCP servers require Node.js but are optional
- Dev container is self-contained and reproducible
- VS Code settings work with or without container
