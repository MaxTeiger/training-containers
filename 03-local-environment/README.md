# Build a local development environment

During this exercise, you will learn how to:

- use Docker Compose
- build a container-based local development environment

The environment will include:

- an event-driven web application with live-reloading
- a Redis queue
- a reverse proxy that routes traffic to different services
- a Prometheus instance for monitoring
- a Grafana instance to display dashboards

## Step 1: Run a reverse proxy

All requests entering our development environment will go through an NGINX
reverse proxy. Here is what you need to do:

1. Create a `docker-compose.yml` file.
2. Add a service to it, called `reverse-proxy`.
3. Use this image: `jwilder/nginx-proxy`. You can find documentation about it on
   [DockerHub](https://hub.docker.com/r/jwilder/nginx-proxy).
4. Mount any volumes the container needs to function.
5. Use `docker compose` to run the service.
6. Make sure the service responds to requests on `http://localhost/`.

Ready? Set. Go!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

```yaml
version: "3.9"
services:
  reverse-proxy:
    image: jwilder/nginx-proxy:0.9-alpine
    ports:
      - 80:80
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
```

You should use this command to start the service:

```bash
docker compose up
```

</details>

## Step 2: Run the producer

It's time to add the first microservice to this local environment. Here is what
you need to do:

1. Add a new service called `producer`.
2. Don't use an image. Instead, build an image based on the `producer`
   directory. Build the `development` stage.
3. Mount the microservice's source code into the container.
4. Add the environment variables required for the reverse proxy to route
   requests to `api.vcap.me` to the microservice.

   > `*.vcap.me` hostnames resolve to `127.0.0.1`. This is very conveniant for
   > local environments!

5. Run the service.
6. Make sure that the service responds to requests sent to
   http://api.vcap.me/healthz.

You can do it!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

> Note that no changes to the `reverse-proxy` service were required.

```yaml
version: "3.9"
services:
  reverse-proxy:
    image: jwilder/nginx-proxy:0.9-alpine
    ports:
      - 80:80
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
  producer:
    build:
      context: ./producer
      target: development
    environment:
      - VIRTUAL_HOST=api.vcap.me # for reverse proxy
      - VIRTUAL_PORT=8080 # for reverse proxy
    volumes:
      - ./producer:/app
```

</details>

## Step 3: Run the consumer

Next, run the second microservice used by this app. Here is what you need to do:

1. Add a new service called `consumer`.
2. Don't use an image. Instead, build an image based on the `consumer`
   directory. Build the `development` stage.
3. Mount the microservice's source code into the container.
4. Run the service.

   > The service should print logs about not finding Redis. This is normal. We
   > will fix it in the next step.

What are you waiting for?

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

```yaml
version: "3.9"
services:
  reverse-proxy:
    # ...
  producer:
    # ...
  consumer:
    build:
      context: ./consumer
      target: development
    volumes:
      - ./consumer:/app
```

</details>

## Step 4: Deploy a Redis server

The application needs a Redis server to work. Let's give it what it wants. Here
is what you need to do:

1. Add a service called `redis`.
2. Persist the server's data in a volume called `redis-data`.
3. Run the server.
4. Send a POST request to http://api.vcap.me/publish and check that the consumer
   logs that it got the message.

Get to it!

> The microservices expect to find a Redis server when sending requests to the
> `redis` hostname. If you want to know where this is configured, it's in the
> `producer/.air.toml` and `consumer/.air.toml` files. The `full_bin` setting is
> where we set flags for the microservices.

<details>
    <summary>Best practice n°1</summary>

When you can, specify a major and minor version for each dependency.

</details>

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

```yaml
version: "3.9"
services:
  reverse-proxy:
    # ...
  producer:
    # ...
  consumer:
    # ...
  redis:
    image: redis:6.2
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
volumes:
  redis-data: {}
```

</details>

## Step 5: Monitor everything with Prometheus

Debugging blind is a nightmare. Distributed systems need monitoring. Here is
what you need to do:

1. Create a service called `redis-exporter` that runs a Prometheus exporter that
   exposes information about the Redis server.
2. Create a service called `prometheus` that runs a Prometheus server.
3. Persist Prometheus' data in a volume called `prometheus-data`.
4. Add the necessary environment variables for the reverse proxy to forward
   requests sent to `prometheus.vcap.me` to the new service.
5. Open http://prometheus.vcap.me/ in your browser. You should see the
   Prometheus UI.
6. Create a `prometheus` directory and mount it inside the Prometheus container
   at `/etc/prometheus`.
7. Create a `preometheus/preometheus.yml` file containing the Prometheus
   server's configuration.
8. Configure the server to scrape for metrics every 5 seconds.
9. Configure the server to scrape:
   - itself
   - both microservices
   - Redis' exporter

Are you ready? Go!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

```yaml
version: "3.9"
services:
  reverse-proxy:
    # ...
  producer:
    # ...
  consumer:
    # ...
  redis:
    # ...
  redis-exporter:
    image: oliver006/redis_exporter:v1.27.0
    environment:
      - REDIS_ADDR=redis://redis:6379
      - REDIS_EXPORTER_CHECK_SINGLE_KEYS=padok
  prometheus:
    image: prom/prometheus:v2.30.0
    environment:
      - VIRTUAL_HOST=prometheus.vcap.me # for reverse proxy
      - VIRTUAL_PORT=9090 # for reverse proxy
    volumes:
      - ./prometheus/:/etc/prometheus/
      - prometheus-data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
volumes:
  prometheus-data: {}
  redis-data: {}
```

Your `prometheus/prometheus.yml` should contain:

```yaml
global:
  scrape_interval: 5s
  scrape_timeout: 1s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - localhost:9090
  - job_name: producer
    static_configs:
      - targets:
          - producer:8080
  - job_name: consumer
    static_configs:
      - targets:
          - consumer:8080
  - job_name: redis
    static_configs:
      - targets:
          - redis-exporter:9121
```

</details>

## Step 6: Add dashboards with Grafana

Collecting metrics is great; displaying them in dashboards is better. Here is
what you need to do:

1. Create a new service called `grafana`.
2. Persist Grafana's data with a volume called `grafana-data`.
3. Disable authentication for Grafana. Anonymous users should be administrators.
   Do this with environment variables.
4. Add the necessary environment variables so that you can see the grafana UI in
   your browser at http://grafana.vcap.me/.
5. Create a `grafana/datasources` directory and mount it inside the container at
   `/etc/grafana/provisioning/datasources`.
6. Create a `grafana/datasources/all.yml` file that configures Grafana to use
   the Prometheus server as a datasource.
7. Create a `grafana/dashboards` directory and mount it inside the container at
   `/var/lib/grafana/dashboards`.
8. Create a `grafana/dashboards/all.yml` file that configures Grafana to
   pre-load all dashboards it finds in `/var/lib/grafana/dashboards`.
9. Create a `grafana/dashboards/redis-exporter.json` file based on the
   community's dashboard for the Prometheus Redis exporter.

   > You will need to make small edits to the JSON found online.

10. Check that when you create the environment from scratch, the dashboard is
    there.

Last step. You're almost done!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `docker-compose.yml` should contain:

```yaml
version: "3.9"
services:
  reverse-proxy:
    # ...
  producer:
    # ...
  consumer:
    # ...
  redis:
    # ...
  redis-exporter:
    # ...
  prometheus:
    # ...
  grafana:
    image: grafana/grafana:8.1.4
    environment:
      - VIRTUAL_HOST=grafana.vcap.me # for reverse proxy
      - VIRTUAL_PORT=3000 # for reverse proxy
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/dashboards:/var/lib/grafana/dashboards
volumes:
  grafana-data: {}
  prometheus-data: {}
  redis-data: {}
```

Your `grafana/datasources/all.yml` should contain:

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
```

Your `grafana/dashboards/all.yml` should contain:

```yaml
providers:
  - name: Pre-loaded local dashboards
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

Your `grafana/dashboards/redis-exporter.json` should contain the JSON
[found here](https://grafana.com/grafana/dashboards/763) with the following
changes:

- The `__inputs` field has been removed.
- All occurences of `${DS_PROM}` have been replaced with `Prometheus`.

</details>

## Bonus step: Create dashboards for the microservices

Prometheus scrapes metrics from the microservices. It would be nice to have
a dashboard for those. Here is what you can do:

1. In the Grafana UI, create a new dashboard.
2. Add useful information about the microservices to the dashboard.

   > You can find the metrics in the Prometheus UI. They start with `producer_`
   > and `consumer_`.

3. Export the dashboard to JSON and add it to the `grafana/dashboards`
   directory.
4. Destroy the environment entirely, including its volumes, with this command:

   ```bash
   docker compose down --volumes
   ```

5. Recreate the environment and check that the dashboard is there from the
   start.

_No solution is provided for this step. Let your creativity guide you._

## Cleanup

Once you are done with this exercise, be sure to delete the containers and
volumes you created:

```bash
docker compose down --volumes
```

I hope you had fun and learned something!
