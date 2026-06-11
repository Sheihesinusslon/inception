# User Documentation

## Services provided

| Service | Description |
|---|---|
| NGINX | HTTPS reverse proxy, sole entry point on port 443 |
| WordPress + PHP-FPM | CMS running on port 9000 (internal) |
| MariaDB | Relational database for WordPress (port 3306, internal) |
| Redis | In-memory object cache for WordPress (port 6379, internal) |

## Start and stop

```sh
make          # start the full stack (builds images on first run)
make down     # stop all containers (data persists)
make re       # wipe and rebuild everything from scratch
```

## Access

| URL | Purpose |
|---|---|
| https://ngusev.42.fr | WordPress site |
| https://ngusev.42.fr/wp-admin | WordPress admin panel |

> The browser will warn about a self-signed certificate — accept the exception to continue.

Default accounts:

| Role | Login | Password source |
|---|---|---|
| Administrator | `ngusev_wp` | Line 1 of `secrets/credentials.txt` |
| Editor (author) | `ngusev_editor` | Line 2 of `secrets/credentials.txt` |

## Credentials location

| Credential | File |
|---|---|
| DB user password | `secrets/db_password.txt` |
| DB root password | `secrets/db_root_password.txt` |
| WP passwords | `secrets/credentials.txt` |

These files are **gitignored**. Keep them safe locally.

## Check services are running

```sh
make ps                      # container status
docker logs nginx            # NGINX logs
docker logs wordpress        # PHP-FPM / WP setup logs
docker logs mariadb          # MariaDB logs
docker logs redis            # Redis logs
docker exec -it redis redis-cli ping   # should return PONG
```
