# Containerize a website

In this exercise, you will learn how to:

- package a static website into a container image
- use custom entrypoints to add runtime behaviour
- run cron tasks inside a container
- inject environment variables into static resources

## Step 1: Get the website up and running

The simplest way to host a website is to run a standard web server.

Here is what you need to do:

1. Create a Dockerfile.
2. Create a container image that runs NGINX.
3. Add your static resources to the Dockerfile.
4. Build the container image.
5. Make the website available at http://localhost:8080/.

Ready? Set. Go!

<details>
    <summary>Best practice n°1</summary>
    Use an existing container image with NGINX inside.
</details>

<details>
    <summary>Best practice n°2</summary>
    Use an Alpine-based container image.
</details>

<details>
    <summary>Best practice n°3</summary>
    Specify the major and minor versions of NGINX.
</details>

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should contain:

```dockerfile
FROM nginx:1.21-alpine

COPY static /usr/share/nginx/html
```

Build and run the container with these commands:

```bash
docker build -t website .
docker run -p 8080:80 website
```

</details>

## Step 2: Download a random image at runtime

Your website always displays the same image. Let's pick a random image when the
server starts.

You are provided with the `download-image.sh` script. The script downloads a
random webcomic to replace the one found in the `static` directory.

> ⚠️ Do not run the script on your machine. Run it where NGINX is running.

Here is what you need to do:

1. Add the `download-image.sh` script to the website's container image.
2. Run the script when the container starts.

   > Hint: the NGINX container image allows you to do both these things at once.

3. Check that the website displays a different image every time the container
   restarts.

You can do it!

<details>
    <summary>Best practice n°1</summary>

When installing packages with a package manager, make sure its cache is deleted
in the same `RUN` instruction.

</details>

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should contain:

```dockerfile
FROM nginx:1.21-alpine

RUN apk add --no-cache jq
COPY download-image.sh /docker-entrypoint.d/40-download-image.sh

COPY static /usr/share/nginx/html
```

</details>

## Step 3: Download a new image every minute

We don't plan on restarting our server frequently, but it would be nice if the
image displayed changed often.

Here is what you need to do:

1. Create a cron configuration file that runs `download-image.sh` every minute.
   Append the script's output to /var/log/cron.log.

   > Hint: You don't need to edit `download-image.sh` in any way.

2. Add the configuration to the container image.
3. Write a script that:
   - runs the cron daemon in the background
   - in the background, streams the contents of /var/log/cron.log to the
     script's standard output.
4. Run the script when the container starts.
5. Confirm that the image updates every minute (you will need to reload the page).

What are you waiting for?

<details>
    <summary>Hint n°1</summary>
The container's cron configuration is stored in `/etc/crontabs/root`.
</details>

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should contain:

```dockerfile
FROM nginx:1.21-alpine

RUN apk add --no-cache jq
COPY download-image.sh /docker-entrypoint.d/40-download-image.sh

COPY crontab /etc/crontabs/root
COPY run-crond.sh /docker-entrypoint.d/50-run-crond.sh

COPY static /usr/share/nginx/html
```

The `crontab` file should contain:

```cron
# All tasks should append all their output to /var/log/cron.log. Anything
# written to that log file will be streamed to the container's standard output.

# Studies show that users get bored of seeing the same image all the time.
* * * * * /docker-entrypoint.d/40-download-image.sh >> /var/log/cron.log 2>&1
```

The `run-crond.sh` script should contain:

```bash
#!/bin/sh

set -e

ME=$(basename "$0")

echo "$ME: Running cron daemon in background..."
crond

echo "$ME: Streaming cron logs to container logs..."
touch /var/log/cron.log
tail -f /var/log/cron.log &
```

</details>

## Step 4: Add the Clamp binary

Next, we want to change the HTML that our website displays. To do this, we are
going to use a tool called [Clamp](https://github.com/JulienBreux/clamp),
written by an engineer Padok once worked with.

Here is what you need to do:

1. Add the Clamp binary to your container image.
2. Use `COPY`'s `--from` flag to do so.

Get to it!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `Dockerfile` should look like this:

```dockerfile
FROM nginx:1.21-alpine

RUN apk add --no-cache jq
COPY download-image.sh /docker-entrypoint.d/40-download-image.sh

COPY crontab /etc/crontabs/root
COPY run-crond.sh /docker-entrypoint.d/50-run-crond.sh

COPY --from=julienbreux/clamp:v1.4.0 /bin/clamp /usr/local/bin/

COPY static /usr/share/nginx/html
```

</details>

## Step 5: Display dynamic debugging info

Now let's use Clamp to display useful debegging info on our website!

Here is what you need to do:

1. Edit `static/index.html`: add templating so that Clamp can inject the values
   of the `HOSTNAME` and `NGINX_VERSION` variables in the website's debugging
   info.
2. Write a script called `render-templates.sh` that injects the container's
   environment variables into `index.html`.
3. Add `render-templates.sh` to your container image.
4. Run the script when the container starts.

Are you ready? Go!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `static/index.html` should contain this:

```html
<!-- ... -->
<h3>Debug information</h3>
<p>Server hostname: {{ .HOSTNAME }}</p>
<p>NGINX version: {{ .NGINX_VERSION }}</p>
<!-- ... -->
```

Your `Dockerfile` should look like this:

```dockerfile
FROM nginx:1.21-alpine

RUN apk add --no-cache jq
COPY download-image.sh /docker-entrypoint.d/40-download-image.sh

COPY crontab /etc/crontabs/root
COPY run-crond.sh /docker-entrypoint.d/50-run-crond.sh

COPY --from=julienbreux/clamp:v1.4.0 /bin/clamp /usr/local/bin/
COPY render-templates.sh /docker-entrypoint.d/60-render-templates.sh

COPY static /usr/share/nginx/html
```

Your `render-templates.sh` should contain this:

```bash
#!/bin/sh

set -e

ME=$(basename "$0")

TEMPLATE_FILE="/usr/share/nginx/html/index.html"
BACKUP="$TEMPLATE_FILE.bkp"

if [ ! -f "$BACKUP" ]; then
    echo "$ME: Backing up $TEMPLATE_FILE to $BACKUP..."
    cp "$TEMPLATE_FILE" "$BACKUP"
fi

echo "$ME: Injecting environment variables into $TEMPLATE_FILE..."
clamp "$BACKUP" > "$TEMPLATE_FILE"

echo "$ME: Environment variables successfully injected."
```

</details>

## Step 6: Display debug info only when debugging

You shouldn't display debugging info in production, only during development.

Here is what you need to do:

- Edit `static/index.html` so that debugging info is displayed only if the
  `DEBUG` environment variable is set to `true`.
- Check that when `DEBUG` is `true`, debugging information is displayed.
- Check that when `DEBUG` is `false` or not set, debugging information is
  hidden.

Last step. You're almost done!

<details>
    <summary><em>
    Compare your work to the solution before moving on. Are there differences? Is your approach better or worse? Why?
    </em></summary>

Your `static/index.html` should look like this:

```html
<!-- ... -->
{{- if eq .DEBUG "true" }}
<h3>Debug information</h3>
<p>Server hostname: {{ .HOSTNAME }}</p>
<p>NGINX version: {{ .NGINX_VERSION }}</p>
{{- end }}
<!-- ... -->
```

The command to run your container should be:

```bash
docker run -p 8080:80 -e DEBUG=true website
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
