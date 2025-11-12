#!/bin/bash

# Enhanced Nix Package Manager
# A contextual, sub-command based script for managing Nix packages

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script name for usage
SCRIPT_NAME=$(basename "$0")

# Configuration
NIX_FLAKE_PATH="${NIX_FLAKE_PATH:-$HOME/.config/nixpkgs-soltros}"
VERBOSE="${VERBOSE:-0}"
QUIET="${QUIET:-0}"

# Logging functions
log_info() {
    [[ "$QUIET" -eq 1 ]] && return
    echo -e "${BLUE}$*${NC}"
}

log_success() {
    [[ "$QUIET" -eq 1 ]] && return
    echo -e "${GREEN}$*${NC}"
}

log_error() {
    echo -e "${RED}$*${NC}" >&2
}

log_warning() {
    [[ "$QUIET" -eq 1 ]] && return
    echo -e "${YELLOW}$*${NC}"
}

log_verbose() {
    [[ "$VERBOSE" -eq 1 ]] && echo -e "${BLUE}[VERBOSE] $*${NC}"
}

# Function to display usage
usage() {
    echo -e "${BLUE}Usage: $SCRIPT_NAME <command> [options]${NC}"
    echo ""
    echo "Commands:"
    echo "  install <package>    Install a package from nixpkgs"
    echo "  remove <package>     Remove an installed package (by name or index)"
    echo "  list                 List installed packages"
    echo "  search <query>       Search for packages in nixpkgs"
    echo "  info <package>       Show information about a package"
    echo "  upgrade              Upgrade all packages"
    echo "  update               Update the Nix flake"
    echo "  history              Show profile history"
    echo "  rollback [num]       Rollback to previous generation (or specified)"
    echo "  clean                Run garbage collection"
    echo "  help                 Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  NIX_FLAKE_PATH       Path to Nix flake (default: ~/.config/nixpkgs-soltros)"
    echo "  VERBOSE=1            Enable verbose output"
    echo "  QUIET=1              Suppress non-error output"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME install firefox"
    echo "  $SCRIPT_NAME remove firefox"
    echo "  $SCRIPT_NAME search vim"
    echo "  $SCRIPT_NAME info htop"
    echo "  $SCRIPT_NAME list"
    echo "  NIX_FLAKE_PATH=~/.config/my-nix $SCRIPT_NAME install vim"
}

# Function to check if nix is available
check_nix() {
    if ! command -v nix &> /dev/null; then
        log_error "Error: Nix is not installed or not in PATH"
        exit 1
    fi
    log_verbose "Nix command found: $(command -v nix)"
}

# Function to validate package name
validate_package_name() {
    local package="$1"

    # Basic validation: no slashes, no spaces, not empty
    if [[ -z "$package" ]]; then
        log_error "Error: Package name cannot be empty"
        return 1
    fi

    if [[ "$package" =~ [[:space:]] ]]; then
        log_error "Error: Package name cannot contain spaces"
        return 1
    fi

    # Allow alphanumeric, dash, underscore, dot
    if [[ ! "$package" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Error: Invalid package name format. Use only letters, numbers, dots, dashes, and underscores"
        return 1
    fi

    return 0
}

# Helper function to update command (reduces duplication)
run_update_command() {
    local cmd="$1"
    shift
    local paths=("$@")

    if ! command -v "$cmd" &> /dev/null; then
        log_verbose "Command '$cmd' not found, skipping"
        return 0
    fi

    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            log_verbose "Running: $cmd $path"
            $cmd "$path" 2>/dev/null || true
        fi
    done
}

# Function to update desktop environment shortcuts
update_desktop_shortcuts() {
    log_info "Updating desktop shortcuts..."

    # Determinate Nix installer paths
    local nix_profile_path="$HOME/.nix-profile"

    # Update desktop database for Nix profile paths
    run_update_command "update-desktop-database" \
        "$nix_profile_path/share/applications" \
        "$HOME/.local/share/applications"

    # Update MIME database for Nix profile
    run_update_command "update-mime-database" \
        "$nix_profile_path/share/mime" \
        "$HOME/.local/share/mime"

    # Update icon cache for Nix profile icons
    if command -v gtk-update-icon-cache &> /dev/null; then
        for icon_path in "$nix_profile_path/share/icons/hicolor" "$HOME/.local/share/icons/hicolor"; do
            if [[ -d "$icon_path" ]]; then
                log_verbose "Updating icon cache: $icon_path"
                gtk-update-icon-cache -f -t "$icon_path" 2>/dev/null || true
            fi
        done
    fi

    # KDE Plasma specific updates
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] || [[ "${DESKTOP_SESSION:-}" == *"plasma"* ]]; then
        log_verbose "Detected KDE/Plasma desktop environment"
        # Force rebuild of KDE service cache to pick up new .desktop files
        if command -v kbuildsycoca6 &> /dev/null; then
            log_verbose "Running kbuildsycoca6"
            kbuildsycoca6 --noincremental 2>/dev/null || true
        elif command -v kbuildsycoca5 &> /dev/null; then
            log_verbose "Running kbuildsycoca5"
            kbuildsycoca5 --noincremental 2>/dev/null || true
        fi

        # Notify KDE about new applications
        if command -v qdbus &> /dev/null; then
            log_verbose "Notifying KDE launcher"
            qdbus org.kde.KLauncher /KLauncher reparseConfiguration 2>/dev/null || true
        fi
    fi

    # GNOME specific updates
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        log_verbose "Detected GNOME desktop environment"
        # Update GNOME's application cache
        run_update_command "glib-compile-schemas" \
            "$nix_profile_path/share/glib-2.0/schemas"
    fi

    # Force XDG to rescan application directories
    if command -v xdg-desktop-menu &> /dev/null; then
        log_verbose "Forcing XDG desktop menu update"
        xdg-desktop-menu forceupdate 2>/dev/null || true
    fi

    # Refresh systemd user environment (for immutable OS integration)
    if command -v systemctl &> /dev/null; then
        log_verbose "Reloading systemd user daemon"
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    # Send SIGHUP to update desktop environment (fixed regex)
    if command -v pkill &> /dev/null; then
        log_verbose "Sending SIGHUP to desktop environments"
        # Use separate pkill calls for each process to avoid regex issues
        pkill -HUP -f "gnome-shell" 2>/dev/null || true
        pkill -HUP -f "plasmashell" 2>/dev/null || true
        pkill -HUP -f "xfce4-panel" 2>/dev/null || true
    fi

    log_success "✓ Desktop shortcuts updated for Nix profile"
}

# Function to install a package
install_package() {
    local package="$1"

    if [[ -z "$package" ]]; then
        log_error "Error: Package name is required"
        echo "Usage: $SCRIPT_NAME install <package>"
        exit 1
    fi

    # Validate package name
    if ! validate_package_name "$package"; then
        exit 1
    fi

    log_info "Installing package: $package"
    log_verbose "Using Nix flake path: $NIX_FLAKE_PATH"

    if nix profile install "$NIX_FLAKE_PATH#$package"; then
        log_success "✓ Successfully installed: $package"
        update_desktop_shortcuts
    else
        log_error "✗ Failed to install: $package"
        echo "Use '$SCRIPT_NAME search $package' to find available packages"
        exit 1
    fi
}

# Function to remove a package
remove_package() {
    local specified_package="$1"

    if [[ -z "$specified_package" ]]; then
        log_error "Error: Package identifier (name, index, or path) is required"
        echo "Usage: $SCRIPT_NAME remove <identifier>"
        exit 1
    fi

    log_info "Attempting to remove: $specified_package"
    log_verbose "This will remove the package from the Nix profile"

    # Directly pass the provided argument to 'nix profile remove'
    if nix profile remove "$specified_package"; then
        log_success "✓ Successfully removed: $specified_package"
        update_desktop_shortcuts
    else
        log_error "✗ Failed to remove: $specified_package"
        echo "Use '$SCRIPT_NAME list' to find the correct identifier."
        exit 1
    fi
}

# Function to list installed packages
list_packages() {
    log_info "Installed packages:"
    nix profile list
}

# Function to search for packages
search_packages() {
    local query="$1"

    if [[ -z "$query" ]]; then
        log_error "Error: Search query is required"
        echo "Usage: $SCRIPT_NAME search <query>"
        exit 1
    fi

    log_info "Searching for packages matching: $query"
    NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "$query"
}

# Function to show package information
info_package() {
    local package="$1"

    if [[ -z "$package" ]]; then
        log_error "Error: Package name is required"
        echo "Usage: $SCRIPT_NAME info <package>"
        exit 1
    fi

    log_info "Fetching information for: $package"
    # Show detailed package information
    NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "^$package$" --json | \
        nix eval --json --expr 'builtins.fromJSON (builtins.readFile /dev/stdin)' 2>/dev/null || \
        NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "$package"
}

# Function to upgrade all packages
upgrade_packages() {
    log_info "Upgrading all packages..."
    log_verbose "This will upgrade all installed packages to their latest versions"

    if nix profile upgrade '.*'; then
        log_success "✓ All packages upgraded successfully"
        update_desktop_shortcuts
    else
        log_error "✗ Failed to upgrade packages"
        exit 1
    fi
}

# Function to update the Nix flake
update_flake() {
    log_info "Updating Nix flake..."
    log_verbose "Flake path: $NIX_FLAKE_PATH"

    if [[ -d "$NIX_FLAKE_PATH" ]]; then
        if nix flake update "$NIX_FLAKE_PATH"; then
            log_success "✓ Flake updated successfully"
        else
            log_error "✗ Failed to update flake"
            exit 1
        fi
    else
        log_warning "Flake directory not found: $NIX_FLAKE_PATH"
        log_info "Attempting to update flake lock..."
        if nix flake update; then
            log_success "✓ Flake updated successfully"
        else
            log_error "✗ Failed to update flake"
            exit 1
        fi
    fi
}

# Function to show profile history
show_history() {
    log_info "Profile history:"
    nix profile history
}

# Function to rollback profile
rollback_profile() {
    local generation="$1"

    log_info "Rolling back profile..."

    if [[ -n "$generation" ]]; then
        log_verbose "Rolling back to generation: $generation"
        if nix profile rollback --to "$generation"; then
            log_success "✓ Rolled back to generation $generation"
            update_desktop_shortcuts
        else
            log_error "✗ Failed to rollback to generation $generation"
            exit 1
        fi
    else
        log_verbose "Rolling back to previous generation"
        if nix profile rollback; then
            log_success "✓ Rolled back to previous generation"
            update_desktop_shortcuts
        else
            log_error "✗ Failed to rollback"
            exit 1
        fi
    fi
}

# Function to run garbage collection
clean_profile() {
    log_info "Running garbage collection..."
    log_verbose "This will remove unused packages and free up disk space"

    if nix-collect-garbage -d; then
        log_success "✓ Garbage collection completed successfully"
    else
        log_error "✗ Failed to run garbage collection"
        exit 1
    fi
}

# Main function to handle commands
main() {
    # Check if nix is available
    check_nix

    # Check if at least one argument is provided
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi

    local command="$1"
    shift  # Remove command from arguments

    case "$command" in
        install)
            if [[ $# -eq 0 ]]; then
                log_error "Error: Package name is required"
                echo "Usage: $SCRIPT_NAME install <package>"
                exit 1
            fi
            if [[ $# -gt 1 ]]; then
                log_warning "Warning: Extra arguments ignored: ${*:2}"
            fi
            install_package "$1"
            ;;
        remove)
            if [[ $# -eq 0 ]]; then
                log_error "Error: Package identifier is required"
                echo "Usage: $SCRIPT_NAME remove <identifier>"
                exit 1
            fi
            if [[ $# -gt 1 ]]; then
                log_warning "Warning: Extra arguments ignored: ${*:2}"
            fi
            remove_package "$1"
            ;;
        list)
            if [[ $# -gt 0 ]]; then
                log_warning "Warning: 'list' command takes no arguments, ignoring: $*"
            fi
            list_packages
            ;;
        search)
            if [[ $# -eq 0 ]]; then
                log_error "Error: Search query is required"
                echo "Usage: $SCRIPT_NAME search <query>"
                exit 1
            fi
            if [[ $# -gt 1 ]]; then
                log_warning "Warning: Extra arguments ignored: ${*:2}"
            fi
            search_packages "$1"
            ;;
        info)
            if [[ $# -eq 0 ]]; then
                log_error "Error: Package name is required"
                echo "Usage: $SCRIPT_NAME info <package>"
                exit 1
            fi
            if [[ $# -gt 1 ]]; then
                log_warning "Warning: Extra arguments ignored: ${*:2}"
            fi
            info_package "$1"
            ;;
        upgrade)
            if [[ $# -gt 0 ]]; then
                log_warning "Warning: 'upgrade' command takes no arguments, ignoring: $*"
            fi
            upgrade_packages
            ;;
        update)
            if [[ $# -gt 0 ]]; then
                log_warning "Warning: 'update' command takes no arguments, ignoring: $*"
            fi
            update_flake
            ;;
        history)
            if [[ $# -gt 0 ]]; then
                log_warning "Warning: 'history' command takes no arguments, ignoring: $*"
            fi
            show_history
            ;;
        rollback)
            if [[ $# -gt 1 ]]; then
                log_warning "Warning: Extra arguments ignored: ${*:2}"
            fi
            rollback_profile "$1"
            ;;
        clean)
            if [[ $# -gt 0 ]]; then
                log_warning "Warning: 'clean' command takes no arguments, ignoring: $*"
            fi
            clean_profile
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Error: Unknown command '$command'"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
