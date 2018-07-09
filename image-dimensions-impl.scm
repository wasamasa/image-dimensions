(define (read-bytes in len)
  (let ((bytes (read-u8vector len in)))
    (when (< (u8vector-length bytes) len)
      (error "unexpected EOF"))
    bytes))

(define (skip-bytes in len)
  (let loop ((i 0))
    (when (< i len)
      (when (eof-object? (read-char in))
        (error "unexpected EOF"))
      (loop (add1 i)))))

(define (read-u8 in)
  (if (eof-object? (peek-char in))
      (error "unexpected EOF")
      (char->integer (read-char in))))

(define (read-u16be in)
  (+ (arithmetic-shift (read-u8 in) 8)
     (read-u8 in)))

(define (read-u16le in)
  (+ (read-u8 in)
     (arithmetic-shift (read-u8 in) 8)))

(define (read-u16 in endianness)
  (case endianness
    ((le) (read-u16le in))
    ((be) (read-u16be in))
    (else (error "unknown endianness"))))

(define (read-u32be in)
  (+ (arithmetic-shift (read-u8 in) 24)
     (arithmetic-shift (read-u8 in) 16)
     (arithmetic-shift (read-u8 in) 8)
     (read-u8 in)))

(define (read-u32le in)
  (+ (read-u8 in)
     (arithmetic-shift (read-u8 in) 8)
     (arithmetic-shift (read-u8 in) 16)
     (arithmetic-shift (read-u8 in) 24)))

(define (read-u32 in endianness)
  (case endianness
    ((le) (read-u32le in))
    ((be) (read-u32be in))
    (else (error "unknown endianness"))))

(define gif-header #u8(#x47 #x49 #x46 #x38))
(define png-header #u8(#x89 #x50 #x4e #x47))
(define tiff-le-header #u8(#x49 #x49 #x2a #x00))
(define tiff-be-header #u8(#x4d #x4d #x00 #x2a))
(define jpeg-header #u8(#xff #xd8 #xff))
(define exif-header #u8(#x45 #x78 #x69 #x66 #x00 #x00))

(define (identify-image-type in)
  (let ((bytes (read-bytes in 3)))
    (if (match-header? jpeg-header bytes)
        'jpeg
        (let ((bytes (list->u8vector (append (u8vector->list bytes)
                                             (list (read-u8 in))))))
          (cond
           ((match-header? gif-header bytes) 'gif)
           ((match-header? png-header bytes) 'png)
           ((match-header? tiff-le-header bytes) 'tiff-le)
           ((match-header? tiff-be-header bytes) 'tiff-be)
           (else 'unknown))))))

(define (match-header? header bytes)
  (if (< (u8vector-length bytes) (u8vector-length header))
      #f
      (let loop ((i 0))
        (if (< i (u8vector-length header))
            (if (= (u8vector-ref header i) (u8vector-ref bytes i))
                (loop (add1 i))
                #f)
            #t))))

;; all of these assume 4 bytes have been read for type identification

(define (gif-info in)
  (skip-bytes in 2)
  (let* ((width (read-u16le in))
         (height (read-u16le in)))
    (list 'gif width height 0)))

(define (png-info in)
  (skip-bytes in 12)
  (let* ((width (read-u32be in))
         (height (read-u32be in)))
    (list 'png width height 0)))

(define (skip-to-tiff-ifd in endianness)
  (let ((offset (read-u32 in endianness)))
    (skip-bytes in (- offset 8))))

(define (scan-tiff-ifd proc in endianness)
  (let ((entry-count (read-u16 in endianness)))
    (call/cc
     (lambda (return)
       (let loop ((i 0))
         (if (< i entry-count)
             (let ((tag (read-u16 in endianness)))
               (proc tag return)
               (loop (add1 i)))
             #f))))))

(define (read-tiff-integer in endianness)
  (let ((type (read-u16 in endianness)))
    (skip-bytes in 4)
    (cond
     ((= type 3)
      (read-u16 in endianness))
     ((= type 4)
      (read-u32 in endianness))
     (else
      (error "couldn't read TIFF integer")))))

(define (tiff-info in endianness)
  (define width-tag #x100)
  (define height-tag #x101)
  (skip-to-tiff-ifd in endianness)
  (let ((width #f)
        (height #f))
    (or
     (scan-tiff-ifd (lambda (tag return)
                      (cond
                       ((and width height)
                        (return (list 'tiff width height 0)))
                       ((= tag width-tag)
                        (set! width (read-tiff-integer in endianness)))
                       ((= tag height-tag)
                        (set! height (read-tiff-integer in endianness)))))
                    in endianness)
     (error "couldn't find TIFF width / height"))))

(define (make-u8vector-input-port bytes)
  (let* ((i 0)
         (peek (lambda () (if (< i (u8vector-length bytes))
                              (integer->char (u8vector-ref bytes i))
                              #!eof))))
    (make-input-port
     ;; read-char
     (lambda ()
       (let ((char (peek)))
         (when (not (eof-object? char))
           (set! i (add1 i)))
         char))
     ;; char-ready?
     (lambda () #t)
     ;; close
     (lambda () #f)
     ;; peek-char
     peek)))

(define (read-byte-until in int)
  (do ((byte -1 (read-u8 in)))
      ((= byte int))))

(define (read-byte-while in int)
  (do ((byte int (read-u8 in)))
      ((not (= byte int))
       byte)))

(define (jpeg-info in)
  (define sof-markers '(#xc0 #xc1 #xc2 #xc3 #xc5 #xc6 #xc7
                             #xc9 #xca #xcb #xcd #xce #xcf))
  (define eoi-marker #xd9)
  (define sos-marker #xda)
  (define app1-marker #xe1)
  (define jpeg-marker #xff)
  (define (read-jpeg-marker in)
    (read-byte-until in jpeg-marker)
    (read-byte-while in jpeg-marker))
  (define (read-frame in)
    (let ((length (read-u16be in)))
      (read-bytes in (- length 2))))
  (define (skip-frame in)
    (let ((length (read-u16be in)))
      (skip-bytes in (- length 2))))
  (define (read-start-of-frame in)
    (let* ((length (read-u16be in))
           (_depth (skip-bytes in 1))
           (height (read-u16be in))
           (width (read-u16be in))
           (size (read-u8 in)))
      (if (= (+ (* size 3) 8) length)
          (list width height)
          (error "malformed SOF frame"))))
  (define (read-app1-frame in)
    (let ((frame (read-frame in)))
      (if (match-header? exif-header frame)
          (let ((data (subu8vector frame
                                   (u8vector-length exif-header)
                                   (u8vector-length frame))))
            (read-exif-data (make-u8vector-input-port data)))
          #f)))
  (define exif-orientation-tag #x112)
  (define (int->angle value)
    (case value
    ;; http://jpegclub.org/exif_orientation.html
      ((0 1 2) 0) ; 0 is actually invalid orientation, but who cares
      ((3 4) 180)
      ((5 6) 90)
      ((7 8) 270)
      (else (error "invalid EXIF orientation"))))
  (define (read-exif-data in)
    ;; yes, EXIF metadata is pretty much TIFF
    (let* ((bytes (read-bytes in 4))
           (endianness (cond
                        ((match-header? tiff-le-header bytes) 'le)
                        ((match-header? tiff-be-header bytes) 'be)
                        (else (error "malformed EXIF frame")))))
      (skip-to-tiff-ifd in endianness)
      (scan-tiff-ifd (lambda (tag return)
                       (when (= tag exif-orientation-tag)
                         (let ((int (read-tiff-integer in endianness)))
                           (return (int->angle int)))))
                     in endianness)))
  (let loop ((marker (read-byte-while in jpeg-marker))
             (angle 0))
    (cond
     ((memv marker sof-markers)
      (let* ((dimensions (read-start-of-frame in))
             (width (car dimensions))
             (height (cadr dimensions))
             (flipped? (or (= angle 90) (= angle 270))))
        (if flipped?
            (list 'jpeg height width angle)
            (list 'jpeg width height angle))))
     ((or (= marker eoi-marker) (= marker sos-marker))
      (error "end of stream"))
     ((= marker app1-marker)
      (let ((angle (or (read-app1-frame in) angle)))
        (loop (read-jpeg-marker in) angle)))
     (else
      (skip-frame in)
      (loop (read-jpeg-marker in) angle)))))

(define (image-info in)
  (case (identify-image-type in)
    ((gif) (gif-info in))
    ((png) (png-info in))
    ((tiff-le) (tiff-info in 'le))
    ((tiff-be) (tiff-info in 'be))
    ((jpeg) (jpeg-info in))
    (else (error "unknown image type"))))

(define (image-dimensions in)
  (take (drop (image-info in) 1) 2))
