// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include "control.h"
#include "control_transport.h"
#include "control_host.h"

void test_xscope(client interface control i[1])
{
  uint32_t buf[XSCOPE_UPLOAD_MAX_WORDS];
  struct control_xscope_response *resp;
  control_version_t version;
  size_t len, len2;
  control_ret_t ret;

  len = control_xscope_create_upload_buffer(buf,
    CONTROL_GET_VERSION, CONTROL_SPECIAL_RESID,
    NULL, sizeof(control_version_t));

  ret = control_process_xscope_upload(buf, len, len2, i, 1);
  resp = (struct control_xscope_response*)buf;
  version = *((control_version_t*)resp->data);

  if (ret != CONTROL_SUCCESS) {
    printf("xSCOPE processing function returned %d\n", ret);
    exit(1);
  }
  if (resp->ret != CONTROL_SUCCESS) {
    printf("xSCOPE response return code %d\n", resp->ret);
    exit(1);
  }
  else if (version != CONTROL_VERSION) {
    printf("xSCOPE returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void test_usb(client interface control i[1])
{
  uint16_t windex, wvalue, wlength;
  uint8_t data[8];
  control_version_t version;
  control_ret_t ret;

  control_usb_fill_header(&windex, &wvalue, &wlength,
    CONTROL_SPECIAL_RESID, CONTROL_GET_VERSION, sizeof(control_version_t));

  ret = control_process_usb_get_request(windex, wvalue, wlength, data, i, 1);
  memcpy(&version, data, sizeof(control_version_t));

  if (ret != CONTROL_SUCCESS) {
    printf("USB processing function returned %d\n", ret);
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("USB returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void test_i2c(client interface control i[1])
{
  uint8_t buf[I2C_TRANSACTION_MAX_BYTES];
  control_version_t version;
  control_ret_t ret;
  uint8_t data[8];
  size_t len;
  int j;

  len = control_build_i2c_data(buf, CONTROL_SPECIAL_RESID,
    CONTROL_GET_VERSION, data, sizeof(control_version_t));

  ret = CONTROL_SUCCESS;
  ret |= control_process_i2c_write_start(i, 1);
  for (j = 0; j < len; j++) {
    ret |= control_process_i2c_write_data(buf[j], i, 1);
  }
  ret |= control_process_i2c_read_start(i, 1);
  for (j = 0; j < sizeof(control_version_t); j++) {
    ret |= control_process_i2c_read_data(data[j], i, 1);
  }
  memcpy(&version, data, sizeof(control_version_t));
  ret |= control_process_i2c_stop(i, 1);

  if (ret != CONTROL_SUCCESS) {
    printf("I2C processing functions returned %d\n", ret);
    exit(1);
  }
  if (version != CONTROL_VERSION) {
    printf("I2C returned control version 0x%X, expected 0x%X\n", version, CONTROL_VERSION);
    exit(1);
  }
}

void dummy_user_task(server interface control i)
{
  // nothing
}

int main(void)
{
  interface control i[1];
  par {
    { test_xscope(i);
      test_usb(i);
      test_i2c(i);
      printf("Success!\n");
      exit(0);
    }
    dummy_user_task(i[0]);
    { delay_microseconds(1000);
      printf("test timeout\n");
      exit(1);
    }
  }
  return 0;
}
