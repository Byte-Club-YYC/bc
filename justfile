set dotenv-load

build-client:
	cd client; gleam run -m lustre/dev build app

run-server:
	cd server; gleam run

format:
	cd client; gleam format
	cd server; gleam format
