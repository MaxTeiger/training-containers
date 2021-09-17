# Containerize a microservice

During this exercise, you will learn how to:

- package a microservice into a container image
- use multi-stage container builds
- implement live reloading

## Step 1: Get the backend running

You have a simple microservice you want to deploy. First, get it running inside
a container. Everything you need to know is in the `main.go` and `go.mod` files.

Here is what you need to do:

1. Write a `Dockerfile`.
2. In the `Dockerfile`, download the microservice's dependencies.
3. In the `Dockerfile`, build the microservice.
4. When the container starts, run the microservice.
5. Build a container image.
6. Run the container.
7. Check that the microservice responds to requests on
   http://localhost:8080/healthz.

> Don't worry about multi-stage builds for now.

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should look like:

```dockerfile
FROM golang:1.16-alpine

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY main.go main.go
RUN go build -ldflags="-s -w" -o=microservice

EXPOSE 8080
ENTRYPOINT ["/app/microservice"]
```

The commands you use to build and run the container should be:

```bash
docker build -t microservice .
docker run -p 8080:8080 microservice
```

</details>

## Step 2: Enable caching for the Go compiler

If you make a small change in `main.go` and rebuild your container image,
Docker will need to rebuild the binary from scratch. Docker does not know to
persist Go's build cache to make successive builds faster. Here is what you
need to do:

1. Use BuildKit's caching feature to persist Go's build cache.
2. Make a small change in `main.go`, like a comment or a log message.
3. Rebuild your image. Take note of how long compiling the binary took.
4. Make another small change in `main.go`.
5. Rebuild your image. How much faster was it?

> This step is considered to be Level 2 in difficulty. You can skip it if you
> feel this is too difficult.

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

The `RUN` instruction that builds the binary should look like this:

```dockerfile
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -ldflags="-s -w" -o=microservice
```

</details>

## Step 3: Use multi-stage builds to produce a smaller image

The image you built so far is pretty large because it contains the entire Go
toolkit. It's time to make it smaller. Much smaller. Here is what you need to
do:

1. Check to see how big your container image is.
2. Change the `go build` command to make the binary statically linked (if you
   don't know what that means, just ask!).
3. In your `Dockerfile`, create a second stage that starts from `scratch`.
4. Copy the binary from the first stage to the second.
5. In the second stage, run the microservice.
6. Build your container image again.
7. Check to see how big the image is now.

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should look like this:

```dockerfile
FROM golang:1.16-alpine AS build

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY main.go main.go
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o=microservice

# =========================================================

FROM scratch

COPY --from=build /app/microservice /microservice

EXPOSE 8080
ENTRYPOINT ["/microservice"]
```

</details>

## Step 4: Implement live reloading for faster development

As a developer, rebuilding the container image manually every time I make a
change to my source code is a waste of time. Time to set up some live reloading!
Here is what you need to do:

1. In your `Dockerfile`, create a new stage specifically for development.
2. In this stage, install [air](https://github.com/cosmtrek/air), a live
   reloading tool for Go.
3. In this stage, run `air` instead of your microservice.
4. Build a container image, targeting this new stage.
5. Run the container, mounting the source code into the container so `air` can
   read it.
6. Make sure the microservice still works.
7. Make a change in `main.go` to make sure live reloading takes place as
   expected.
8. Build the container image without specifying a target. Make sure this builds
   a production image, not a development one.

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should look like this:

```dockerfile
FROM golang:1.16-alpine AS base

WORKDIR /app

# =========================================================

FROM base AS development

RUN go install github.com/cosmtrek/air@v1.27.3

EXPOSE 8080
CMD ["air"]

# =========================================================

FROM base AS build

COPY go.* ./
RUN go mod download

COPY main.go main.go
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o=microservice

# =========================================================

FROM scratch AS production

COPY --from=build /app/microservice /microservice

EXPOSE 8080
ENTRYPOINT ["/microservice"]
```

To build and run your container with live reloading, you should use:

```bash
docker build -t microservice --target=development .
docker run -it -p 8080:8080 -v $PWD:/app microservice
```

These commands should still work as before:

```bash
docker build -t microservice .
docker run -p 8080:8080 microservice
```

</details>

## Cleanup

Once you are done with this exercise, be sure to delete the containers you
created:

```bash
docker ps --quiet | xargs docker stop
docker ps --quiet --all | xargs docker rm
```

I hope you had fun and learned something!
