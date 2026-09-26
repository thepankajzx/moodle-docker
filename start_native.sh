#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=================================================="
echo "ðŸš€ Starting Ultra-Fast Native Moodle 4.5 Cloud Server"
echo "=================================================="

# 1. Start MariaDB & Create Database
sudo service mariadb start || true
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost' IDENTIFIED BY 'moodlepass'; FLUSH PRIVILEGES;"

# 2. Install PHP & Required Extensions
sudo apt-get install -y php php-cli php-mysql php-curl php-zip php-gd php-intl php-xml php-mbstring php-soap php-bcmath

# 3. Clone Moodle 4.5 LTS if not present
MOODLE_DIR="${SCRIPT_DIR}/moodle"
if [ ! -d "$MOODLE_DIR/.git" ]; then
    echo "ðŸ“¦ Cloning Moodle 4.5 LTS..."
    git clone --branch MOODLE_405_STABLE --depth 1 https://github.com/moodle/moodle.git "$MOODLE_DIR"
fi

# 4. Inject local_webhookengine plugin
if [ -f "${SCRIPT_DIR}/local_webhookengine.zip" ]; then
    echo "ðŸ”Œ Injecting local_webhookengine Lite plugin..."
    mkdir -p "$MOODLE_DIR/local/webhookengine"
    unzip -q -o "${SCRIPT_DIR}/local_webhookengine.zip" -d /tmp/plugin_extract
    cp -r /tmp/plugin_extract/webhookengine/* "$MOODLE_DIR/local/webhookengine/" 2>/dev/null || cp -r /tmp/plugin_extract/* "$MOODLE_DIR/local/webhookengine/" 2>/dev/null || true
    rm -rf /tmp/plugin_extract
fi

# 5. Create config.php
sudo mkdir -p /var/moodledata
sudo chmod -R 777 /var/moodledata "$MOODLE_DIR"

CODESPACE_HOST="${CODESPACE_NAME}-8000.app.github.dev"
if [ -z "$CODESPACE_NAME" ]; then
    CODESPACE_HOST="localhost:8000"
fi

cat << EOF > "$MOODLE_DIR/config.php"
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '127.0.0.1';
\$CFG->dbname    = 'moodle';
\$CFG->dbuser    = 'moodle';
\$CFG->dbpass    = 'moodlepass';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

\$host = !empty(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : '${CODESPACE_HOST}';
\$CFG->wwwroot   = "https://{\$host}";
\$CFG->sslproxy  = true;
\$CFG->dataroot  = '/var/moodledata';
\$CFG->admin     = 'admin';
\$CFG->directorypermissions = 0777;

\$CFG->debug = (E_ALL);
\$CFG->debugdisplay = 1;

require_once(__DIR__ . '/lib/setup.php');
EOF

echo "ðŸ› ï¸ Installing Moodle Database (Admin: admin / Admin@1234)..."
php "$MOODLE_DIR/admin/cli/install_database.php" \
  --agree-license \
  --fullname="Moodle 4.5 Demo Platform" \
  --shortname="MoodleDemo" \
  --adminuser=admin \
  --adminpass=Admin@1234 \
  --adminemail=admin@demo.com

echo "ðŸ”„ Activating local_webhookengine plugin..."
php "$MOODLE_DIR/admin/cli/upgrade.php" --non-interactive || true

echo "ðŸ“š Generating realistic Demo Courses and Users..."
php "$MOODLE_DIR/admin/tool/generator/cli/maketestcourse.php" --shortname="DEMO101" --size="S" || true

echo "ðŸŒ Starting Moodle High-Performance Server on Port 8000..."
pkill -f "php -S 0.0.0.0:8000" 2>/dev/null || true
nohup php -S 0.0.0.0:8000 -t "$MOODLE_DIR" > /tmp/moodle_server.log 2>&1 &
sleep 2

echo "=================================================="
echo "ðŸŽ‰ MOODLE 4.5 LTS + WEBHOOK ENGINE IS READY & LIVE!"
echo "Login: admin"
echo "Pass:  Admin@1234"
echo "URL:   https://${CODESPACE_HOST}"
echo "Direct Plugin: Site admin > Plugins > Local plugins > Event Webhooks"
echo "=================================================="