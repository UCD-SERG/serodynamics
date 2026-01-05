#!/bin/bash
# Workflow Comparison Helper Script
# This script helps extract timing information from GitHub Actions workflow logs

set -e

echo "=========================================="
echo "PAK_PREFER_BINARY Experiment Log Helper"
echo "=========================================="
echo ""
echo "This script helps you extract timing information from workflow logs."
echo ""
echo "INSTRUCTIONS:"
echo "1. Go to the Actions tab on GitHub"
echo "2. Find your workflow runs (control and experiment)"
echo "3. For each platform/R version combination:"
echo "   a. Click on the job (e.g., 'CONTROL-default ubuntu-latest (release)')"
echo "   b. Look for these step logs:"
echo "      - 'Record dependency installation end time' - shows DEPS_DURATION"
echo "      - 'Record workflow end time' - shows TOTAL_DURATION"
echo "   c. Record the values in EXPERIMENT_RESULTS_TEMPLATE.md"
echo ""
echo "KEY METRICS TO EXTRACT:"
echo "- Dependency installation: Look for 'Dependency installation took X seconds'"
echo "- Total workflow: Look for 'Total workflow: X seconds'"
echo "- PAK setting: Look for 'PAK_PREFER_BINARY: X'"
echo ""
echo "COMPARISON EXAMPLE:"
echo "If Control shows 'Dependency installation took 180 seconds'"
echo "And Experiment shows 'Dependency installation took 350 seconds'"
echo "Then the difference is +170 seconds (experiment is slower)"
echo ""
echo "=========================================="
echo ""

# Function to calculate percentage difference
calc_percent() {
    local control=$1
    local experiment=$2
    if [ "$control" -eq 0 ]; then
        echo "N/A"
    else
        local diff=$((experiment - control))
        local percent=$((diff * 100 / control))
        echo "${percent}%"
    fi
}

# Interactive mode
echo "Would you like to enter timing data for comparison? (y/n)"
read -r answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo ""
    echo "Enter Control dependency installation time (seconds):"
    read -r control_dep
    echo "Enter Experiment dependency installation time (seconds):"
    read -r exp_dep
    
    echo "Enter Control total workflow time (seconds):"
    read -r control_total
    echo "Enter Experiment total workflow time (seconds):"
    read -r exp_total
    
    dep_diff=$((exp_dep - control_dep))
    total_diff=$((exp_total - control_total))
    
    echo ""
    echo "=========================================="
    echo "COMPARISON RESULTS:"
    echo "=========================================="
    echo "Dependency Installation:"
    echo "  Control:     ${control_dep} seconds"
    echo "  Experiment:  ${exp_dep} seconds"
    echo "  Difference:  ${dep_diff} seconds ($(calc_percent "$control_dep" "$exp_dep"))"
    echo ""
    echo "Total Workflow:"
    echo "  Control:     ${control_total} seconds"
    echo "  Experiment:  ${exp_total} seconds"
    echo "  Difference:  ${total_diff} seconds ($(calc_percent "$control_total" "$exp_total"))"
    echo "=========================================="
fi

echo ""
echo "For detailed analysis, see EXPERIMENT_RESULTS_TEMPLATE.md"
