# Laravel Dockerized Starter

A minimal Laravel environment fully containerized with Docker, ready for development.

## Requirements
- Docker

## Quick Start

### Download the repository using `curl` or `git`:

Option 1. Download via `curl`:
```bash
curl -L -o main.zip https://github.com/RonasIT/laravel-project-create/archive/refs/heads/main.zip &&
unzip main.zip &&
rm main.zip &&
cd laravel-project-create-main
```

Option 2. Clone via `git`:
```bash
git clone git@github.com:RonasIT/laravel-project-create.git NEW-PROJECT-NAME && cd NEW-PROJECT-NAME
```

### Setup and Initialize Project

Before running, make sure you don’t have other Docker containers running.

```bash
./setup.sh
```

### Laravel project is ready for development!