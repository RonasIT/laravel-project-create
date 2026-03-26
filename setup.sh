#!/bin/bash
set -e

# Terminal colors
RED_COLOR='\033[1;31m'
GREEN_COLOR='\033[1;32m'
DEFAULT_COLOR='\033[0m'

# --------------------------------------------------
# Prompt the user with a Yes/No question.
#
# Arguments:
#   $1 - Prompt message
#
# Returns:
#   0 - yes ("y" or "yes")
#   1 - no or any other input
# --------------------------------------------------
prompt_yes_no() {
    local message=$1
    local answer
    read -rp "$message [y/N]: " answer </dev/tty

    answer=$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')
    [[ "$answer" == "y" || "$answer" == "yes" ]]
}

# Prompt for project directory name
while true; do
    echo
    read -rp "Enter the project directory name: " project_dir </dev/tty
    if [ -z "$project_dir" ]; then
        printf "%b\n" "${RED_COLOR}Directory name cannot be empty.${DEFAULT_COLOR}"
    elif [[ ! "$project_dir" =~ ^[a-zA-Z0-9\ _-]+$ ]]; then
        printf "%b\n" "${RED_COLOR}Invalid directory name. Allowed characters: a-z, A-Z, 0-9, space, -, _.${DEFAULT_COLOR}"
    else
        printf "%b\n" "${GREEN_COLOR}Project directory: ${project_dir}${DEFAULT_COLOR}"
        echo
        break
    fi
done

# If the project directory already exists and is not empty, prompt before continuing.
if [ -d "$project_dir" ] && [ -n "$(find "$project_dir" -maxdepth 1 -mindepth 1 2>/dev/null | head -1)" ]; then
    if ! prompt_yes_no "Directory '$project_dir' already exists and is not empty. Continue and potentially overwrite existing files?"; then
        printf "%b\n" "${RED_COLOR}Aborting to avoid modifying existing directory.${DEFAULT_COLOR}"
        exit 1
    fi
fi

mkdir -p "$project_dir"
cd "$project_dir"

# --------------------------------------------------
# Download a file if it does not exist.
#
# Arguments:
#   $1 - Output file path
#   $2 - Source URL
#   $3 - Make file executable ("true" or "false", optional)
#   $4 - Overwrite if file exists ("true" or "false", optional)
# --------------------------------------------------
download_file() {
    local output=$1
    local url=$2
    local make_executable=${3:-false}
    local overwrite=${4:-false}

    if [ -f "$output" ] && [ "$overwrite" != "true" ]; then
        return
    fi

    if curl -fL -o "$output" "$url"; then
        if [ "$make_executable" = "true" ]; then
            chmod +x "$output"
        fi
    else
        printf "%b\n" "${RED_COLOR}Failed to download $output${DEFAULT_COLOR}" >&2
        exit 1
    fi
}


# --------------------------------------------------
# Create initial Git commit for the repository.
# --------------------------------------------------
init_git_repo() {
    git add . &>/dev/null
    git commit -m "chore: initial commit" &>/dev/null
}

# --------------------------------------------------
# Validate SSH Git repository URL.
# --------------------------------------------------
is_valid_ssh_url() {
    [[ "$1" =~ ^git@[^:]+:[^/]+/.+\.git$ ]]
}

# --------------------------------------------------
# Checks whether a Git repository is accessible via SSH.
# --------------------------------------------------
is_repo_accessible() {
    git ls-remote "$1" &>/dev/null
}

# --------------------------------------------------
# Prompt user and add Git remote repository if confirmed.
# --------------------------------------------------
prompt_and_add_git_remote() {
    if prompt_yes_no "Do you want to add a remote Git repository?"; then
        while true; do
            echo
            read -rp "Enter the SSH Git repository URL of the project: " repo_url </dev/tty

            if ! is_valid_ssh_url "$repo_url"; then
                printf "%b\n" "${RED_COLOR}Invalid SSH URL. Example: git@github.com:user/repo.git${DEFAULT_COLOR}"
                continue
            fi

            if ! is_repo_accessible "$repo_url"; then
                printf "%b\n" "${RED_COLOR}Cannot access repository at '$repo_url'. Check URL or SSH keys.${DEFAULT_COLOR}"
                continue
            fi

            git remote add origin "$repo_url"
            printf "%b\n" "${GREEN_COLOR}Added new remote 'origin' $repo_url${DEFAULT_COLOR}"
            echo
            break
        done
    fi
}

# ==================================================
# Main script logic
# ==================================================

# Download required files
download_file "init-project.sh" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/init-project.sh" true
download_file "docker-compose.yml" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/docker-compose.yml" false
download_file "Dockerfile" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/Dockerfile" false

mkdir -p docker && touch docker/entrypoint.sh && chmod +x docker/entrypoint.sh

# Git initialization and configuration
if command -v git &>/dev/null; then
    if prompt_yes_no "Do you want to initialize a Git repository?"; then
        git init &>/dev/null
        init_git_repo
        prompt_and_add_git_remote
    fi
fi

# Docker startup and project initialization
if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker compose up -d
    docker compose exec -it nginx bash /app/init-project.sh < /dev/tty
else
    printf "%b\n" "${RED_COLOR}Error: Docker is not installed, not running, or permission denied.${DEFAULT_COLOR}" >&2
    exit 1
fi

download_file "docker/entrypoint.sh" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/entrypoint.sh" true true

echo
printf "%b\n" "${GREEN_COLOR}Setup complete!${DEFAULT_COLOR}"
