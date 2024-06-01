FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

# Add project code
COPY . /build/

# Compile the project
RUN cd /build/client \
  && gleam run -m lustre/dev build app \
  && cd /build/server \
  && gleam export erlang-shipment \
  && mv /build/server/build/erlang-shipment /app \
  && rm -r /build

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
