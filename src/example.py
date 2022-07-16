
import numpy as np
from typing import Optional

status = 0
class MyClass:
    val: Optional[str | float]
    
    def __init__(self, x: Optional[str | float] = None):
        self.val = x
        if self.val is not None:
            my_val = self.val
