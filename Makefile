LOGIN		= ngusev
DATA_PATH	= /home/$(LOGIN)/data
COMPOSE		= docker compose -f srcs/docker-compose.yml --env-file srcs/.env

# Optional single-service selector, e.g. `make up S=wordpress`, `make stop S=nginx`,
# `make rebuild S=wordpress`. Leave empty to act on all containers.
S	=

all:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(COMPOSE) up -d --build

up:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(COMPOSE) up -d $(S)

stop:
	$(COMPOSE) stop $(S)

rebuild:
	$(COMPOSE) up -d --build --no-deps $(S)

down:
	$(COMPOSE) down

re: fclean all

clean: down
	docker system prune -af

fclean:
	$(COMPOSE) down -v --remove-orphans
	docker system prune -af
	sudo rm -rf $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

.PHONY: all up stop rebuild down re clean fclean logs ps
