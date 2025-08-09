# Agent Guidelines for ArduPilot SITL Docker Simulator

## Build/Test Commands
- Build container: `docker-compose build`
- Run simulator: `docker-compose up`
- Build specific platform: `docker buildx build --platform linux/amd64 .`
- Test connection: Connect GCS to `localhost:14550` (UDP)

## Project Structure
- This is a Docker-based ArduPilot SITL simulator project
- Main components: Dockerfile, compose.yml, supervisord.conf, GitHub Actions CI
- Supports Rover (default), Copter, and Plane vehicle types
- Uses supervisord to manage ArduPilot processes inside container

## Configuration Guidelines
- Vehicle type configured in supervisord.conf (default: Rover)
- To change vehicle: modify `[program:rover]` section in supervisord.conf
- ArduPilot builds happen in Dockerfile using waf build system
- Network exposed on host port 14550 for GCS connections

## Docker Best Practices
- Use BuildKit cache mounts for ccache optimization
- Multi-platform builds (linux/amd64, linux/arm64) via GitHub Actions
- Base image: ghcr.io/wkronmiller/ardupilot:master
- Run as non-root user 'ardupilot'

## No Cursor/Copilot Rules Found
- No .cursorrules or copilot-instructions.md files present

## Git

- Use git commit -F commit-message.txt to commit changes
- Commit messages should be clear and descriptive
- Follow conventional commit style for consistency
