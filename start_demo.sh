#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=================================================="
echo "ðŸš€ Starting Official Moodle 4.5 LTS (PostgreSQL Engine)"
echo "=================================================="

export MOODLE_DOCKER_WWWROOT="${SCRIPT_DIR}/moodle"
export MOODLE_DOCKER_DB=pgsql
export MOODLE_DOCKER_PHP_VERSION=8.2
export MOODLE_DOCKER_WEB_PORT=8000

# 1. Checkout Moodle 4.5 LTS
if [ -d "$MOODLE_DOCKER_WWWROOT/.git" ]; then
    echo "ðŸ”„ Switching Moodle to 4.5 LTS (MOODLE_405_STABLE)..."
    cd "$MOODLE_DOCKER_WWWROOT"
    git fetch --depth 1 origin MOODLE_405_STABLE 2>/dev/null || true
    git checkout -f FETCH_HEAD || git checkout -f MOODLE_405_STABLE || true
    cd "$SCRIPT_DIR"
else
    echo "ðŸ“¦ Cloning Moodle 4.5 LTS (MOODLE_405_STABLE)..."
    git clone --branch MOODLE_405_STABLE --depth 1 https://github.com/moodle/moodle.git "$MOODLE_DOCKER_WWWROOT"
fi

# 2. Inject local_webhookengine plugin
if [ -f "${SCRIPT_DIR}/local_webhookengine.zip" ]; then
    echo "ðŸ”Œ Injecting local_webhookengine Lite plugin..."
    mkdir -p "$MOODLE_DOCKER_WWWROOT/local/webhookengine"
    unzip -q -o "${SCRIPT_DIR}/local_webhookengine.zip" -d /tmp/plugin_extract
    cp -r /tmp/plugin_extract/webhookengine/* "$MOODLE_DOCKER_WWWROOT/local/webhookengine/" 2>/dev/null || cp -r /tmp/plugin_extract/* "$MOODLE_DOCKER_WWWROOT/local/webhookengine/" 2>/dev/null || true
    rm -rf /tmp/plugin_extract
fi

echo "âš™ï¸ Configuring Docker Moodle..."
cp config.docker-template.php "$MOODLE_DOCKER_WWWROOT/config.php"
chmod -R 777 "$MOODLE_DOCKER_WWWROOT"

echo "ðŸ³ Starting Docker containers (Postgres 17 + Apache PHP 8.2)..."
bin/moodle-docker-compose down 2>/dev/null || true
bin/moodle-docker-compose up -d

echo "â³ Waiting 10s for PostgreSQL container to be ready..."
sleep 10

echo "ðŸ› ï¸ Installing Moodle Database (Admin: admin / Admin@1234)..."
bin/moodle-docker-compose exec -T webserver php admin/cli/install_database.php \
  --agree-license \
  --fullname="Moodle 4.5 Demo Platform" \
  --shortname="MoodleDemo" \
  --adminuser=admin \
  --adminpass=Admin@1234 \
  --adminemail=admin@demo.com

echo "ðŸ”„ Activating local_webhookengine plugin..."
bin/moodle-docker-compose exec -T webserver php admin/cli/upgrade.php --non-interactive || true

echo "ðŸ“š Generating realistic Demo Courses and Users..."
bin/moodle-docker-compose exec -T webserver php admin/tool/generator/cli/maketestcourse.php --shortname="DEMO101" --size="S" || true

echo "=================================================="
echo "ðŸŽ‰ MOODLE 4.5 LTS + WEBHOOK ENGINE IS READY & LIVE!"
echo "Login: admin"
echo "Pass:  Admin@1234"
echo "Check Port 8000 -> Open in Browser"
echo "=================================================="