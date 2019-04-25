import os
while not any([x in  [".git","files"] for x in os.listdir()]):
  os.chdir("..")
print("Working Directory: " + os.getcwd())

import sys
if not os.getcwd() in sys.path:
    sys.path.append(os.getcwd())