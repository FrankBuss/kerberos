/*
 * ef3xfer.h
 *
 *  Created on: 26.01.2012
 *      Author: skoe
 */

#ifndef EF3XFER_H_
#define EF3XFER_H_

#ifdef __cplusplus
extern "C" {
#endif

#define EF3XFER_RESP_SIZE (4 + 1)

void ef3xfer_set_callbacks(
        void (*custom_log_str)(const char* str),
        void (*custom_log_progress)(int percent, int b_gui_only));

int ef3xfer_raw_send(const char* p_filename);

int ef3xfer_transfer_crt(const char* p_filename);

int ef3xfer_transfer_prg(const char* p_filename);
int ef3xfer_transfer_prg_mem(const unsigned char* p_prg, int size);

int ef3xfer_d64_write(const char* p_filename, int drv, int do_format);

int ef3xfer_usb_test(void);

#ifdef __cplusplus
}
#endif

#endif /* EF3XFER_H_ */
