#ifndef ErrorHandling_h
#define ErrorHandling_h

@import Foundation;
@import Clibpng;

extern BOOL try_png_read_frame_head(int *jmp_buf, png_structp png_ptr, png_infop info_ptr);

#endif /* ErrorHandling_h */
