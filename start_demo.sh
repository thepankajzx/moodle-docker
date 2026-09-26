#!/bin/bash
set -e

echo "=================================================="
echo "ðŸš€ Starting Complete Moodle 5.0 Cloud Demo Server"
echo "=================================================="

WORKSPACE_DIR="$(pwd)"
export MOODLE_DOCKER_WWWROOT="${WORKSPACE_DIR}/moodle"
export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_PHP_VERSION=8.2

if [ ! -d "$MOODLE_DOCKER_WWWROOT" ]; then
    echo "ðŸ“¦ Cloning Moodle 5.0 (master branch)..."
    git clone --branch master --depth 1 https://github.com/moodle/moodle.git "$MOODLE_DOCKER_WWWROOT"
fi

echo "âš™ï¸ Configuring Docker Moodle..."
cp config.docker-template.php "$MOODLE_DOCKER_WWWROOT/config.php"

echo "ðŸ³ Starting Docker containers..."
bin/moodle-docker-compose up -d

echo "â³ Waiting for MariaDB & Webserver to be ready..."
sleep 15

echo "ðŸ› ï¸ Installing Moodle Database (Admin: admin / Admin@1234)..."
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php \
  --agree-license \
  --fullname="Moodle 5.0 Demo Platform" \
  --shortname="MoodleDemo" \
  --adminuser=admin \
  --adminpass=Admin@1234 \
  --adminemail=admin@demo.com

echo "ðŸ“š Generating realistic Demo Courses and Users..."
bin/moodle-docker-compose exec webserver php admin/tool/generator/cli/maketestcourse.php --shortname="DEMO50" --size="S" || true

echo "=================================================="
echo "ðŸŽ‰ MOODLE 5.0 IS FULLY INSTALLED & RUNNING!"
echo "Login: admin"
echo "Pass:  Admin@1234"
echo "Check the PORTS tab (Port 8000) -> Click 'Open in Browser'"
echo "=================================================="