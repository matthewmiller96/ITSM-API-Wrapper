from dotenv import load_dotenv
from pathlib import Path
import os

# Load environment variables before importing app
env_path = Path(__file__).parent / "config" / "fedex" / ".env"
load_dotenv(dotenv_path=env_path)

from main import app

if __name__ == "__main__":
    debug_mode = os.getenv('FLASK_DEBUG', 'False').lower() in ['true', '1', 't']
    app.run(debug=debug_mode)