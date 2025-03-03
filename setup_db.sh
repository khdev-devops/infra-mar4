#!/bin/bash
# ====================================================
# Bash-script för att sätta upp postgres databas
# för en python app
# ====================================================

set -e  # Stoppa scriptet vid fel

function print {
  echo -e "\n\033[1m─────────────────────────────────────────────"
  echo "$1"
  echo -e "─────────────────────────────────────────────\033[0m\n"
}

check_env_var() {
    local var_name="$1"

    if [[ -n "${!var_name}" ]]; then
        echo "✅ Miljövariabeln '$var_name' finns"
        return 0  # Indikerar framgång
    else
        echo "❌ Miljövariabeln '$var_name' är inte satt eller är tom."
        echo "Värde sätts med: export $var_name='värde'"
        return 1  # Indikerar fel
    fi
}

#######################################
print "0: Kollar miljövariabler (environment variables)"
#######################################

check_env_var "DB_NAME"
check_env_var "DB_USER"
check_env_var "DB_PASSWORD"
PERSON_NAME_IN_DB="Kalle"

#######################################
print "1: Uppdaterar serverns mjukvarupaket"
#######################################

sudo dnf update -y

#######################################
print "2: Installerar och konfigurerar PostgreSQL"
#######################################

sudo dnf install -y postgresql16 postgresql16-server

# Se om initdb behövs genom att kolla om katalogen finns
if [ ! -d "/var/lib/pgsql/data" ]; then
  sudo postgresql-setup --initdb
  echo "✅ Initierat PostgreSQL datakatalog"
else
  echo "ℹ️ PostgreSQL-datakatalogen finns redan, hoppar över initiering."
fi

sudo systemctl start postgresql
sudo systemctl enable postgresql

# Kontrollera om databasen finns
DB_EXISTS=$(sudo -i -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';")
if [[ "$DB_EXISTS" != "1" ]]; then
  sudo -i -u postgres psql -c "CREATE DATABASE $DB_NAME;"
  echo "✅ Databasen $DB_NAME skapad!"
else
  echo "ℹ️ Databasen $DB_NAME finns redan."
fi

# Kontrollera om användaren finns
USER_EXISTS=$(sudo -i -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';")
USER_EXISTS=$(sudo -i -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';")
if [[ "$USER_EXISTS" != "1" ]]; then
  sudo -i -u postgres psql -c "CREATE USER $DB_USER;"
  echo "✅ Användaren $DB_USER skapad!"
else
  echo "ℹ️ Användaren $DB_USER finns redan."
fi

# Uppdatera alltid lösenordet för att se till att det är korrekt
sudo -i -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
echo "✅ Lösenordet för $DB_USER uppdaterat!"


# Kontrollera om användaren har rättigheter på databasen
PERMISSION_EXISTS=$(sudo -i -u postgres psql -tAc "SELECT 1 FROM pg_shdepend WHERE objid = (SELECT oid FROM pg_database WHERE datname = '$DB_NAME') AND refobjid = (SELECT oid FROM pg_roles WHERE rolname = '$DB_USER');")
if [[ "$PERMISSION_EXISTS" != "1" ]]; then
  sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
  echo "✅ Rättigheter för $DB_USER på $DB_NAME beviljade!"
else
  echo "ℹ️ Rättigheter för $DB_USER på $DB_NAME finns redan."
fi

# Kontrollera om tabellen users finns
TABLE_EXISTS=$(sudo -i -u postgres psql -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='users';")
if [[ "$TABLE_EXISTS" != "1" ]]; then
  sudo -i -u postgres psql -d "$DB_NAME" -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50));"
  echo "✅ Tabellen 'users' skapad!"
else
  echo "ℹ️ Tabellen 'users' finns redan."
fi

# Kontrollera om användaren redan finns i tabellen
USER_IN_DB=$(sudo -i -u postgres psql -d "$DB_NAME" -tAc "SELECT 1 FROM users WHERE name='$PERSON_NAME_IN_DB';")
if [[ "$USER_IN_DB" != "1" ]]; then
  sudo -i -u postgres psql -d "$DB_NAME" -c "INSERT INTO users (name) VALUES ('$PERSON_NAME_IN_DB');"
  echo "✅ Användaren '$PERSON_NAME_IN_DB' tillagd i users-tabellen!"
else
  echo "ℹ️ Användaren '$PERSON_NAME_IN_DB' finns redan i users-tabellen."
fi

# Kontrollera och ge nödvändiga rättigheter
SCHEMA_USAGE=$(sudo -i -u postgres psql -d "$DB_NAME" -tAc "SELECT has_schema_privilege('$DB_USER', 'public', 'USAGE');")
if [[ "$SCHEMA_USAGE" != "t" ]]; then
  sudo -i -u postgres psql -d "$DB_NAME" -c "GRANT USAGE ON SCHEMA public TO $DB_USER;"
  echo "✅ USAGE-rättigheter för $DB_USER på public-schema beviljade!"
fi

TABLE_SELECT=$(sudo -i -u postgres psql -d "$DB_NAME" -tAc "SELECT has_table_privilege('$DB_USER', 'users', 'SELECT');")
if [[ "$TABLE_SELECT" != "t" ]]; then
  sudo -i -u postgres psql -d "$DB_NAME" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $DB_USER;"
  echo "✅ SELECT-rättigheter för $DB_USER på users-tabellen beviljade!"
fi
PSQL_AUTH_FILE="/var/lib/pgsql/data/pg_hba.conf"
if ! sudo grep -q "host    $DB_NAME            $DB_USER" "$PSQL_AUTH_FILE"; then
  sudo sed -i "1i host    $DB_NAME            $DB_USER          127.0.0.1/32            md5" "$PSQL_AUTH_FILE"
  echo "✅ Rättigheter för flask-app att accessa postgres mha user/pw tillagt"
  sudo systemctl restart postgresql
else
  echo "ℹ️ Rättigheter för flask-app att accessa postgres finns redan"
fi

print "Klart: ✅ Databas skapad och access konfigurerad!"
