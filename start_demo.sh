#!/bin/bash
set -e

echo "=================================================="
echo "ðŸš€ Starting Official Moodle 4.5 LTS Cloud Demo Server"
echo "=================================================="

WORKSPACE_DIR="$(pwd)"
export MOODLE_DOCKER_WWWROOT="${WORKSPACE_DIR}/moodle"
export MOODLE_DOCKER_DB=mariadb
export MOODLE_DOCKER_PHP_VERSION=8.2

# If moodle dir exists but is on wrong branch/version, re-clone clean 4.5 LTS
if [ -d "$MOODLE_DOCKER_WWWROOT/.git" ]; then
    echo "ðŸ”„ Switching Moodle to 4.5 LTS (MOODLE_405_STABLE)..."
    cd "$MOODLE_DOCKER_WWWROOT"
    git fetch --depth 1 origin MOODLE_405_STABLE
    git checkout -f FETCH_HEAD
    cd "$WORKSPACE_DIR"
else
    echo "ðŸ“¦ Cloning Moodle 4.5 LTS (MOODLE_405_STABLE)..."
    git clone --branch MOODLE_405_STABLE --depth 1 https://github.com/moodle/moodle.git "$MOODLE_DOCKER_WWWROOT"
fi

echo "âš™ï¸ Configuring Docker Moodle..."
cp config.docker-template.php "$MOODLE_DOCKER_WWWROOT/config.php"

echo "ðŸ³ Starting Docker containers..."
bin/moodle-docker-compose up -d

echo "â³ Waiting 10s for database..."
sleep 10

echo "ðŸ› ï¸ Installing Moodle Database (Admin: admin / Admin@1234)..."
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php \
  --agree-license \
  --fullname="Moodle 4.5 Demo Platform" \
  --shortname="MoodleDemo" \
  --adminuser=admin \
  --adminpass=Admin@1234 \
  --adminemail=admin@demo.com

echo "ðŸ“š Generating realistic Demo Courses and Users..."
bin/moodle-docker-compose exec webserver php admin/tool/generator/cli/maketestcourse.php --shortname="DEMO101" --size="S" || true

echo "=================================================="
echo "ðŸŽ‰ MOODLE 4.5 LTS IS FULLY INSTALLED & READY!"
echo "Login: admin"
echo "Pass:  Admin@1234"
echo "Go to PORTS tab -> Port 8000 -> Click 'Open in Browser'"
echo "=================================================="