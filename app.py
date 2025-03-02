import os
from flask import Flask
import psycopg2

app = Flask(__name__)

DB_HOST = "127.0.0.1"
DB_NAME = None
DB_USER = None
DB_PASSWORD = None


# Steg 1: Kontrollera miljövariabler
def check_env_variables():
    """Kontrollerar att alla nödvändiga miljövariabler finns och hämtar deras värden."""
    global DB_NAME, DB_USER, DB_PASSWORD

    required_env_vars = ["DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing_vars = [var for var in required_env_vars if os.getenv(var) is None]

    if missing_vars:
        return f"❌ Följande miljövariabler saknas: {', '.join(missing_vars)}", False

    DB_NAME = os.getenv("DB_NAME")
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")

    return "✅ Steg 1: Alla miljövariabler är korrekt inställda!", True


# Steg 2: Testa anslutning till databasen
def check_db_connection():
    """Kontrollerar om Flask kan ansluta till databasen."""
    conn = get_db_connection()
    if isinstance(conn, str):
        return f"❌ Steg 2: Databasanslutning misslyckades: {conn}", False
    conn.close()
    return "✅ Steg 2: Flask kan ansluta till databasen!", True


# Steg 3: Hämta data från databasen
def fetch_user_from_db():
    """Försöker hämta en användare från databasen."""
    result, success = execute_db_query('SELECT name FROM users LIMIT 1;', fetch_one=True)
    
    if not success:
        return result, False
    if result:
        return f"✅ Steg 3: Flask kan hämta data från databasen! (Användare: {result[0]})", True
    return "❌ Steg 3: Ingen användare hittades i databasen!", False


# Databasanslutning
def get_db_connection():
    """Försöker ansluta till PostgreSQL och returnerar anslutningen eller ett felmeddelande."""
    try:
        return psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
    except Exception as e:
        return str(e)

# Generisk funktion för att köra databasfrågor
def execute_db_query(query, fetch_one=False):
    """Kör en SQL-fråga och returnerar resultatet eller ett felmeddelande."""
    conn = get_db_connection()

    if isinstance(conn, str):
        return f"❌ Databasanslutning misslyckades: {conn}", False

    try:
        cur = conn.cursor()
        cur.execute(query)
        result = cur.fetchone() if fetch_one else None
        conn.commit()
        cur.close()
        conn.close()
        return result, True
    except Exception as e:
        return f"❌ Fel vid databasfråga: {e}", False



# Route: Flask-appen själv (ska visa "Hej Kalle!")
@app.route('/')
def home():
    """Hämtar en användare från databasen och visar den på hemsidan."""
    result, success = fetch_user_from_db()
    
    if not success:
        return f"<h1>{result}</h1>", 500
    return f"<h1>Hej, {result.split(': ')[-1]}!</h1>"


# Route: Test och status av alla steg
@app.route('/status')
def status():
    """Visar status för alla steg och indikerar om appen är redo."""
    steps = [
        check_env_variables(),
        check_db_connection(),
        fetch_user_from_db()
    ]

    status_messages = [message for message, _ in steps]

    # Om alla steg är klara, lägg till ett slutmeddelande
    if all(success for _, success in steps):
        status_messages.append("🎉 **Allt fungerar! Flask kan ansluta till databasen och hämta data!**")

    return "<br>".join(status_messages)


# Start av Flask-applikationen
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)