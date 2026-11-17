"""Start the RC-V console: python tools/console.py  (then open http://localhost:8066)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rcv.serve import main  # noqa: E402

main()
