(import scheme)
(cond-expand
 (chicken-4
  (use image-dimensions test))
 (chicken-5
  (import image-dimensions)
  (import test)))

(test-group "GIF"
  (test '(gif 10 20 0) (call-with-input-file "10x20.gif" image-info))
  (test '(10 20) (call-with-input-file "10x20.gif" image-dimensions)))

(test-group "PNG"
  (test '(png 10 20 0) (call-with-input-file "10x20.png" image-info))
  (test '(10 20) (call-with-input-file "10x20.png" image-dimensions)))

(test-group "TIFF"
  (test '(tiff 10 20 0) (call-with-input-file "10x20_lsb.tiff" image-info))
  (test '(10 20) (call-with-input-file "10x20_lsb.tiff" image-dimensions))
  (test '(tiff 10 20 0) (call-with-input-file "10x20_msb.tiff" image-info))
  (test '(10 20) (call-with-input-file "10x20_msb.tiff" image-dimensions)))

(test-group "JPEG"
  (test '(jpeg 10 20 0) (call-with-input-file "10x20.jpg" image-info))
  (test '(10 20) (call-with-input-file "10x20.jpg" image-dimensions))
  (test '(jpeg 10 20 0) (call-with-input-file "10x20_1.jpg" image-info))
  (test '(10 20) (call-with-input-file "10x20_1.jpg" image-dimensions))
  (test '(jpeg 10 20 0) (call-with-input-file "10x20_2.jpg" image-info))
  (test '(10 20) (call-with-input-file "10x20_2.jpg" image-dimensions))
  (test '(jpeg 10 20 180) (call-with-input-file "10x20_3.jpg" image-info))
  (test '(10 20) (call-with-input-file "10x20_3.jpg" image-dimensions))
  (test '(jpeg 10 20 180) (call-with-input-file "10x20_4.jpg" image-info))
  (test '(10 20) (call-with-input-file "10x20_4.jpg" image-dimensions))
  (test '(jpeg 10 20 90) (call-with-input-file "20x10_5.jpg" image-info))
  (test '(10 20) (call-with-input-file "20x10_5.jpg" image-dimensions))
  (test '(jpeg 10 20 90) (call-with-input-file "20x10_6.jpg" image-info))
  (test '(10 20) (call-with-input-file "20x10_6.jpg" image-dimensions))
  (test '(jpeg 10 20 270) (call-with-input-file "20x10_7.jpg" image-info))
  (test '(10 20) (call-with-input-file "20x10_7.jpg" image-dimensions))
  (test '(jpeg 10 20 270) (call-with-input-file "20x10_8.jpg" image-info))
  (test '(10 20) (call-with-input-file "20x10_8.jpg" image-dimensions)))
