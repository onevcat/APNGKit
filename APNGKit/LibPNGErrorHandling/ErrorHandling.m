@import Darwin;
@import Foundation;

#import "ErrorHandling.h"

BOOL try_png_read_frame_head(int *jmp_buf, png_structp png_ptr, png_infop info_ptr) {
    if (!setjmp(jmp_buf)) {
        png_read_frame_head(png_ptr, info_ptr);
        return YES;
    }
    else {
        // the structs will be cleaned in Disassembler
        return NO;
    }
}
