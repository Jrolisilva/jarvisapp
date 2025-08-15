SHELL = /bin/bash
.ONESHELL:

processor.up:
	@echo 'Initializing processor...'
	@docker compose -f payment-processor/docker-compose.yml up -d --build

processor.down:
	@echo 'Stopping processor...'
	@docker compose -f payment-processor/docker-compose.yml down

jarvisapp.up:
	@echo 'Initializing Jarvis app...'
	@docker compose up -d --build

jarvisapp.down:
	@echo 'Stopping Jarvis app...'
	@docker compose down

rinha.test:
	@k6 run rinha-test/rinha.js