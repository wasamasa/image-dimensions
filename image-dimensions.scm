(module image-dimensions
 (image-dimensions image-info)

 (import scheme)
 (cond-expand
  (chicken-4
   (import chicken)
   (use ports srfi-1 srfi-4))
  (chicken-5
   (import (chicken base))
   (import (chicken bitwise))
   (import (chicken port))
   (import (srfi 1))
   (import (srfi 4))))

 (include "image-dimensions-impl.scm"))
