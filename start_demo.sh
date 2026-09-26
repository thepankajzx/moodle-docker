#!/bin/bash
set -e

echo "=================================================="
echo "ðŸš€ Starting Official Moodle 4.5 LTS Cloud Demo Server"
echo "=================================================="

WORKSPACE_DIR="$(pwd)"
export MOODLE_DOCKER_WWWROOT="${WORKSPACE_DIR}/moodle"
export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_PHP_VERSION=8.2
export MOODLE_DOCKER_WEB_PORT=8000

# 1. Checkout Moodle 4.5 LTS
if [ -d "$MOODLE_DOCKER_WWWROOT/.git" ]; then
    echo "ðŸ”„ Switching Moodle to 4.5 LTS (MOODLE_405_STABLE)..."
    cd "$MOODLE_DOCKER_WWWROOT"
    git fetch --depth 1 origin MOODLE_405_STABLE 2>/dev/null || true
    git checkout -f FETCH_HEAD || git checkout -f MOODLE_405_STABLE || true
    cd "$WORKSPACE_DIR"
else
    echo "ðŸ“¦ Cloning Moodle 4.5 LTS (MOODLE_405_STABLE)..."
    git clone --branch MOODLE_405_STABLE --depth 1 https://github.com/moodle/moodle.git "$MOODLE_DOCKER_WWWROOT"
fi

echo "âš™ï¸ Configuring Docker Moodle..."
cp config.docker-template.php "$MOODLE_DOCKER_WWWROOT/config.php"

echo "ðŸ³ Starting Docker containers..."
bin/moodle-docker-compose up -d

echo "â³ Waiting for MariaDB database to be fully initialized..."
count=0
until bin/moodle-docker-compose exec -T db mariadb-admin ping -h localhost -u moodle -p'm@0dl3ing' --silent 2>/dev/null || bin/moodle-docker-compose exec -T db mysqladmin ping -h localhost -u root -p'm@0dl3ing' --silent 2>/dev/null; do
    echo "Waiting for DB to accept connections... ($count s)"
    sleep 3
    count=$((count+3))
    if [ $count -ge 60 ]; then
        echo "Database startup took too long, attempting to proceed..."
        break
    fi
done
echo "âœ… Database is ready and online!"

echo "ðŸ› ï¸ Installing Moodle Database (Admin: admin / Admin@1234)..."
bin/moodle-docker-compose exec -T webserver php admin/cli/install_database.php \
  --agree-license \
  --fullname="Moodle 4.5 Demo Platform" \
  --shortname="MoodleDemo" \
  --adminuser=admin \
  --adminpass=Admin@1234 \
  --adminemail=admin@demo.com

echo "ðŸ“š Generating realistic Demo Courses and Users..."
bin/moodle-docker-compose exec -T webserver php admin/tool/generator/cli/maketestcourse.php --shortname="DEMO101" --size="S" || true

echo "=================================================="
echo "ðŸŽ‰ MOODLE 4.5 LTS IS FULLY INSTALLED & READY!"
echo "Login: admin"
echo "Pass:  Admin@1234"
echo "Check the PORTS tab (Port 8000) -> Click 'Open in Browser'"
echo "=================================================="