from database import engine

try:
    connection = engine.connect()
    print("✅ Conexiune reușită la baza de date MySQL!")
    connection.close()
except Exception as e:
    print("❌ Eroare la conectare:", e)
