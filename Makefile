# ============================================================
#  Inception - Makefile
# ============================================================

DATA_DIR		= /home/$(USER)/data

COMPOSE_FILE	= srcs/docker-compose.yml
COMPOSE			= docker compose -f $(COMPOSE_FILE)

#  Main rules

all: up

build:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	$(COMPOSE) build

up: build
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

#  Cleaning rules

clean: down
	docker system prune -af

fclean: clean
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	docker volume prune -af
	docker network prune -f

re: fclean all

#  Debug / utility rules

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

.PHONY: all build up down start stop restart clean fclean re ps logs