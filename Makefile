NAME = inception

all:
	@mkdir -p /home/tlaranje/data/mariadb
	@mkdir -p /home/tlaranje/data/wordpress
	docker compose -f srcs/docker-compose.yml up --build -d

clean:
	docker compose -f srcs/docker-compose.yml down

fclean: clean
	docker system prune -af --volumes
	sudo rm -rf /home/tlaranje/data

re: fclean all

.PHONY: all clean fclean re