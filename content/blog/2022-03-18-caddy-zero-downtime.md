title = "Zero Downtime Deploys with Caddy"
description = "Use Caddy's reverse proxy to deploy your site without downtime"
date = "2022-03-18T00:05:19Z"
tags = ["caddy", "ops"]
[extra]
author = "Brian Ketelsen"
author_page = "/author/butcher"
---

## Maximum Uptime
I love [Caddy](https://caddyserver.com/) for its simplicity and power. In this article I'll show you how I used the `reverse_proxy` directive to manage updates to my site without downtime.

Let's set the stage... I'm running this blog using [Spin](https://github.com/fermyon/spin) and [Caddy](https://caddyserver.com/). Spin is a web server that processes your requests using applications compiled to WASI. I run two instances of spin, load balanced behind a reverse proxy using Caddy.

The problem I set out to solve is how to update the content of the site without any downtime. Spin won't notice any changes to the files it is serving, so I have to manually restart each instance when there is new content. Here's how I went about it:

### Step 1: Create a two spin instances

I created `systemd` unit files for two instances of spin running on ports 3000 and 3001.

Here's the first one:

```
[Unit]
Description=Bartholomew Blog served by Spin
Requires=network.target
After=network.target

[Service]
Type=simple
User=spin
Group=spin
WorkingDirectory=/opt/spin/wasmblog
ExecStart=/usr/local/bin/spin up --listen 127.0.0.1:3000 --file spin.toml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

The second one is the same, but it listens on port 3001 instead of 3000.

### Step 2: Create a reverse proxy

I installed Caddy, then used this configuration file to create a reverse proxy.

```
spin.brian.dev {
	reverse_proxy localhost:3000 localhost:3001 {
        lb_policy round_robin
        lb_try_duration 2s
        health_uri /healthz
        health_interval 1s
        health_timeout 500ms

    }
}
```
This configuration tells Caddy to service requests by choosing a spin instance from the two available instances. The important piece of this is the `lb_try_duration` directive. Without it, Caddy will return a 502 error if the spin instance is unavailable. With this directive, Caddy will try to connect any spin instance for the specified duration, and won't return an error until the duration has been reached.

### Step 3: Create a health check

This was the easiest part. Spin has a built-in health endpoint at `/healthz` that returns `OK` if the instance is running.

### Step 4: Update the content

The content is stored in a git repository and cloned on the host at `/opt/spin/wasmblog`. I use the `git` command to pull the latest changes from the repository. If the git hash is different after pulling, there's been an update, so we'll restart the services. Here's the script that does it:

```bash
#!/bin/bash

cd /opt/spin/wasmblog || exit
old_version="$(git rev-parse --short HEAD)"
git pull && chown -R spin:spin .
new_version="$(git rev-parse --short HEAD)"

if [ "$old_version" = "$new_version" ]; then
    echo "No changes"
    exit 0
else
    echo "Changes detected, restarting services"
    systemctl restart bartholomew.service
    sleep 10
    systemctl restart bartholomew2.service
fi

```

### Step 5: Schedule the update

Here's where I learned something new. I used a systemd timer to schedule the update. Systemd timers are scheduled to run at specific times, and they'll fire off a service with the same name when the timer executes.

Here is the timer:

update-bart.timer
```
[Unit]
Description=Blog Update Timer

[Timer]
OnCalendar=*-*-* *:0/5
AccuracySec=1s

[Install]
WantedBy=timers.target
```

And the service it fires:

update-bart.service
```
[Unit]
Description=Update blog content

[Service]
Type=oneshot
User=root
Group=root
WorkingDirectory=/opt/spin/wasmblog
ExecStart=/opt/spin/wasmblog/contrib/update.sh

[Install]
WantedBy=multi-user.target

```

### Step 6: Install everything

I created a one-time script to install everything.

```
#!/bin/bash

cp ./contrib/systemd/bartholomew.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew.service
systemctl start bartholomew.service
systemctl status bartholomew.service

cp ./contrib/systemd/bartholomew2.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable bartholomew2.service
systemctl start bartholomew2.service
systemctl status bartholomew2.service

cp ./contrib/systemd/update-bart.service /etc/systemd/system/
cp ./contrib/systemd/update-bart.timer /etc/systemd/system/

systemctl enable update-bart.timer

systemctl restart update-bart.timer

cp ./contrib/caddy/Caddyfile /etc/caddy/
chown -R root:root /etc/caddy/

systemctl restart caddy.service
```

The timer fires every 5 minutes, which starts the update-bart service. The update-bart service runs the update script, which updates the content of the blog, then restarts the spin instances sequentially with a 10s delay. I could have added more logic to the update script for safety to ensure that each service is actually running before moving on to the next one. Maybe another day I'll look at that. For now this is good enough.

## Optional: Use Caddy API to remove backends

Caddy has an API that listens on localhost only, so you could use it to remove the backends from the reverse proxy before restarting them.  Here's a taste of what that looks like:

```
both='[{"dial": "localhost:3000"},{"dial": "localhost:3001"}]'
first='[{"dial": "localhost:3000"}]'
last='[{"dial": "localhost:3001"}]'

echo "Removing port 3000"
curl -X PATCH \
    -H "Content-Type: application/json" \
    -d "$last" \
    "http://localhost:2019/config/apps/http/servers/srv0/routes/0/handle/0/routes/0/handle/0/upstreams"

```
This method guarantees that the spin instances won't be in the pool when the update is happening. I love it when everything has an API.
## Conclusion

Using a combination of systemd timers and systemd services to orchestrate services is a great way to manage your uptime. The key is correctly configuring the load balancer and health checks.

### References and Further Reading

* [Caddy](https://caddyserver.com/) - A fast, modern, and reliable reverse proxy and web server with automatic HTTPS
* [Spin](https://github.com/fermyon/spin) - a web server that processes your requests using applications compiled to WASI
* [Systemd](https://www.freedesktop.org/wiki/Software/systemd/)
* [Bartholomew](https://github.com/fermyon/bartholomew) - a MicroCMS that compiles to WASI
* [This blog's source code](https://github.com/bketelsen/wasmblog)

