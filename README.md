# Laravel Docker Project

Minimal Laravel environment fully containerized with Docker.

## Start

```bash
# Download repository via curl
curl -L -o create-project.zip https://github.com/RonasIT/laravel-project-create/archive/refs/heads/main.zip &&
unzip create-project.zip &&
rm create-project.zip &&
cd laravel-project-create-create-project

# Clone the repository and enter the folder
git clone git@github.com:RonasIT/laravel-project-create.git NEW-PROJECT-NAME && cd NEW-PROJECT-NAME

# Setup Git remote
./setup-git-remote.sh

# Start Docker containers
docker compose up -d

# Run app setup
docker compose exec -it nginx bash /app/setup.sh
```

#### Project is ready for development!