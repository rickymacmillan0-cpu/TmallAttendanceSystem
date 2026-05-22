"""天猫商城员工考勤管理系统 - 应用包。"""

import sys
from pathlib import Path

__version__ = "0.1.0"

# backend/ 目录：保证可 import models、database（与 init_data.py 一致）
_BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))
