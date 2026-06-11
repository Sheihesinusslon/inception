*This project has been created as part of the 42 curriculum by ngusev.*

## Description

Inception is a system administration project that sets up a small web infrastructure using Docker Compose. It runs WordPress backed by MariaDB, served through NGINX over HTTPS (TLSv1.2/1.3), with Redis object cache as a bonus service. Each service lives in its own container built from a custom Dockerfile based on Alpine 3.20.

## Instructions

### Prerequisites

- Docker + Docker Compose v2
- `make`
- Add `ngusev.42.fr` to `/etc/hosts` pointing to `127.0.0.1`

### Setup secrets (required before first run)

Create the three secret files — they are gitignored and must never be committed:

```sh
echo "your_db_user_password"   > secrets/db_password.txt
echo "your_db_root_password"   > secrets/db_root_password.txt
printf "your_admin_password\nyour_editor_password\n" > secrets/credentials.txt
```

- **Line 1** of `credentials.txt` → WordPress admin password (admin login: `ngusev_wp`)
- **Line 2** of `credentials.txt` → WordPress editor password (login: `ngusev_editor`)

### Run

```sh
make          # build images, create data dirs, start stack
make down     # stop containers
make re       # full rebuild from scratch
make fclean   # remove containers + persistent data
make logs     # follow logs
```

The site is available at **https://ngusev.42.fr** after startup.  
WordPress admin panel: **https://ngusev.42.fr/wp-admin**

## Project Description

### Use of Docker

Each service (NGINX, WordPress/PHP-FPM, MariaDB, Redis) runs in a dedicated container built from a custom Dockerfile. No pre-built application images are used; only Alpine 3.20 as the base.

### Design Choices

| Topic | Choice | Reason |
|---|---|---|
| Base image | Alpine 3.20 (penultimate stable) | Minimal footprint, fast build |
| TLS | Self-signed cert, TLSv1.2+1.3 | Requirement; generated at first start |
| PID 1 | `exec` in all entrypoints | Process replaces shell → proper signal handling |
| Secrets | Docker secrets (files in `/run/secrets/`) | Passwords never in env vars or Dockerfiles |

### Virtual Machines vs Docker

VMs virtualise hardware and run a full OS kernel per instance. Docker containers share the host kernel and isolate only at the process level, making them faster to start, smaller in memory, and easier to compose — but offering weaker isolation than a VM.

### Secrets vs Environment Variables

Environment variables are visible to any process in the container and can leak through `docker inspect`. Docker secrets mount sensitive data as in-memory files at `/run/secrets/`, readable only by the process that needs them, and not exposed in image metadata.

### Docker Network vs Host Network

`network: host` removes network isolation — the container shares the host's network stack, which is forbidden by the subject. A user-defined bridge network (`inception`) gives each container its own IP, DNS resolution by service name, and full isolation from the host and other networks.

### Docker Volumes vs Bind Mounts

Bind mounts couple the container to a specific host path and are disallowed by the subject for persistent data. Named volumes (with `driver: local` + `device:` option) are managed by Docker, portable in description, and stored at `/home/ngusev/data` on the host.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [NGINX FastCGI + PHP-FPM](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [MariaDB docker best practices](https://mariadb.com/kb/en/installing-and-using-mariadb-via-docker/)
- [WP-CLI handbook](https://developer.wordpress.org/cli/commands/)
- [Redis Object Cache plugin](https://wordpress.org/plugins/redis-cache/)
- [PID 1 in containers — Phusion blog](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)

**AI usage:** Claude (Sonnet 4.6) was used to scaffold Dockerfile structures, nginx config templates, and MariaDB init script patterns. All generated content was reviewed, tested, and understood before inclusion.
