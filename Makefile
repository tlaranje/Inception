NAME = inception
LOGIN = tlaranje
DATA_DIR = /home/$(LOGIN)/data
COMPOSE = docker compose -f srcs/docker-compose.yml

all: prepare up

up:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

prepare:
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

clean: down
	docker system prune -f

fclean: clean
	sudo rm -rf $(DATA_DIR)
	docker volume rm $$(docker volume ls -q | grep $(NAME)) 2>/dev/null || true

re: fclean all

.PHONY: all up down prepare start stop restart logs status clean fclean re
