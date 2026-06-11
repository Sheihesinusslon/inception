LOGIN		= ngusev
DATA_PATH	= /home/$(LOGIN)/data
COMPOSE		= docker compose -f srcs/docker-compose.yml --env-file srcs/.env

all:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(COMPOSE) up -d --build

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

.PHONY: all down re clean fclean logs ps
