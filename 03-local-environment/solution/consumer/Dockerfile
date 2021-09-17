FROM golang:1.16-alpine AS base

WORKDIR /app

# =====================================================

FROM base AS development

RUN go install github.com/cosmtrek/air@v1.27.3

EXPOSE 8080
CMD ["air"]

# =====================================================

FROM base AS build

COPY go.* ./
RUN go mod download

COPY main.go main.go
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o=consumer

# =====================================================

FROM scratch AS production

COPY --from=build /app/consumer /consumer

EXPOSE 8080
ENTRYPOINT ["/consumer"]
