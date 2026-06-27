LOGIN		= ngusev
DATA_PATH	= /home/$(LOGIN)/data
COMPOSE		= docker compose -f srcs/docker-compose.yml --env-file srcs/.env

# Optional service selector: pass S=<service> to target a single container,
# e.g. `make up S=wordpress`, `make stop S=nginx`, `make rebuild S=wordpress`.
# Leave S empty to act on all containers.
S		=

all:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(COMPOSE) up -d --build

# Bring containers up without rebuilding (all, or a single S=<service>).
up:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(COMPOSE) up -d $(S)

# Stop and remove containers, no image/volume prune (all, or a single S=<service>).
stop:
	$(if $(S),$(COMPOSE) rm -sf $(S),$(COMPOSE) down)

# Rebuild and restart (all, or a single S=<service>) without touching its deps.
rebuild:
	$(COMPOSE) up -d --build --no-deps $(S)

down:
	$(COMPOSE) down

re: fclean all

clean: down
	docker system prune -af

fclean: clean
	sudo rm -rf $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

.PHONY: all up stop rebuild down re clean fclean logs ps
