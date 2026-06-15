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
make ps                      # container status (all should be "Up")
docker logs nginx            # NGINX logs
docker logs wordpress        # PHP-FPM / WP setup logs
docker logs mariadb          # MariaDB logs
docker logs redis            # Redis logs
docker exec -it redis redis-cli ping   # should return PONG
```

## Verify HTTPS / TLS

The site is served **only** over HTTPS on port 443. To confirm the secure connection:

```sh
curl -kIv https://ngusev.42.fr 2>&1 | grep -iE "SSL connection|TLS|HTTP/"
```

- `-k` accepts the self-signed certificate.
- A `HTTP/1.1 200 OK` line means the site is up.
- The negotiated protocol must be **TLSv1.2** or **TLSv1.3** (older versions are refused).

In a browser, click the padlock → *Certificate* to see it is issued for `ngusev.42.fr` (self-signed, valid one year).

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Browser can't reach `ngusev.42.fr` | Add `127.0.0.1 ngusev.42.fr` to `/etc/hosts` |
| "Your connection is not private" warning | Expected — the certificate is self-signed. Click *Advanced → Proceed* |
| A container shows `Restarting` in `make ps` | Read its logs: `docker logs <service>` |
| Can't log in to `/wp-admin` | Check the password matches the correct line of `secrets/credentials.txt` (line 1 = admin) |
| Site loads but looks broken / no styles | Wait a few seconds on first start — WordPress finishes installing in the background |
| Page errors after a crash | Restart the stack: `make down && make` |
