#!/bin/bash
set -e

RED='\033[1;31m'
RESET='\033[0m'

mkdir -p docker

download_file() {
    local output=$1
    local url=$2
    local make_executable=${3:-false}

    if [ -f "$output" ]; then
        return
    fi

    if curl -L -o "$output" "$url"; then
        if [ "$make_executable" = "true" ]; then
            chmod +x "$output"
        fi
    else
        echo "${RED}Failed to download $output${RESET}" >&2
    fi
}

download_file "init-project.sh" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/init-project.sh" true
download_file "docker-compose.yml" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/docker-compose.yml" false
download_file "Dockerfile" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/Dockerfile" false
download_file "docker/entrypoint.sh" "https://raw.githubusercontent.com/RonasIT/laravel-project-create/refs/heads/main/docker/entrypoint.sh" true

prompt_yes_no() {
    local message=$1
    local answer
    read -rp "$message [Y/N]: " answer
    answer=${answer,,}
    [[ "$answer" == "y" || "$answer" == "yes" ]]
}

init_git_repo() {
    git add . &>/dev/null
    git commit -m "chore: initial commit" &>/dev/null
}

is_valid_ssh_url() {
    [[ "$1" =~ ^git@[^:]+:[^/]+/.+\.git$ ]]
}

is_repo_accessible() {
    git ls-remote "$1" &>/dev/null
}

prompt_and_add_git_remote() {
    if prompt_yes_no "Do you want to add a remote Git repository?"; then
        while true; do
            echo
            read -rp "Enter the SSH Git repository URL of the project: " repo_url

            if ! is_valid_ssh_url "$repo_url"; then
                echo "Invalid SSH URL. Example: git@github.com:user/repo.git"
                continue
            fi

            if ! is_repo_accessible "$repo_url"; then
                echo "Cannot access repository at '$repo_url'. Check URL or SSH keys."
                continue
            fi

            git remote add origin "$repo_url"
            echo "Added new remote 'origin' $repo_url"
            break
        done
    fi
}

if command -v git &>/dev/null; then
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git remote get-url origin &>/dev/null && git remote remove origin

        if git rev-parse --verify HEAD &>/dev/null; then
            new_commit=$(git commit-tree HEAD^{tree} -m "chore: initial commit")
            git reset --soft "$new_commit"
            git commit --amend -m "chore: initial commit" &>/dev/null
        else
            init_git_repo
        fi

        prompt_and_add_git_remote
    else
        if prompt_yes_no "Do you want to initialize a Git repository?"; then
            git init &>/dev/null
            init_git_repo
            prompt_and_add_git_remote
        fi
    fi
fi

if command -v docker &>/dev/null && docker info &>/dev/null; then
    docker compose up -d
    docker compose exec -it nginx bash /app/init-project.sh
else
    echo "${RED}Error: Docker is not installed, not running, or permission denied.${RESET}" >&2
    exit 1
fi

rm -- "$(realpath "${BASH_SOURCE[0]}")"