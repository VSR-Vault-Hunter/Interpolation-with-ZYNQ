/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include "display_ctrl/display_ctrl.h"
#include <stdio.h>
#include "math.h"
#include <ctype.h>
#include <stdlib.h>
#include "xil_types.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "vdma/vdma.h"
#include "sleep.h"
#include "xscugic.h"
#include "platform.h"
#include "intr/zynq_interrupt.h"



#define MAX_FRAME 1280*960*3


#define DYNCLK_BASEADDR XPAR_AXI_DYNCLK_0_BASEADDR
#define VDMA_ID 		XPAR_AXIVDMA_0_DEVICE_ID
#define DISP_VTC_ID 	XPAR_VTC_0_DEVICE_ID
#define VID_VTC_IRPT_ID XPS_FPGA3_INT_ID

#define INTC_DEVICE_ID  	XPAR_SCUGIC_SINGLE_DEVICE_ID
#define INTC_BASE_ADDR  	XPAR_SCUGIC_0_CPU_BASEADDR
#define INTC_DIST_BASE_ADDR XPAR_SCUGIC_DIST_BASEADDR

u8 frameBuf[DISPLAY_NUM_FRAMES][MAX_FRAME] __attribute__ ((aligned(64)));
u8 *pFrames[DISPLAY_NUM_FRAMES]; //array of pointers to the frame buffers

DisplayCtrl dispCtrl;
XAxiVdma vdma;
XScuGic XScuGicInstance;

static u8 rd_cnt=0;
static u8 wr_cnt=DISPLAY_NUM_FRAMES/2;
static int writeErr;
static int readErr;
static u8 rd_done = 0;



static void WriteCallBack(void *CallbackRef, u32 Mask);
static void WriteErrCallBack(void *CallbackRef, u32 Mask);

static void ReadCallBack(void *CallbackRef, u32 Mask);
static void ReadErrCallBack(void *CallbackRef, u32 Mask);

void setInputVdma(int width, int height){

	vdma_write_stop(&vdma);
	XAxiVdma_IntrDisable(&vdma, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_WRITE);

	vdma_writes_init(VDMA_ID, &vdma, width * 3, height, width * 3, pFrames);

	XAxiVdma_SetCallBack(&vdma, XAXIVDMA_HANDLER_GENERAL, WriteCallBack, (void *)&vdma, XAXIVDMA_WRITE);
	XAxiVdma_SetCallBack(&vdma, XAXIVDMA_HANDLER_ERROR, WriteErrCallBack, (void *)&vdma, XAXIVDMA_WRITE);

	InterruptConnect(&XScuGicInstance, XPAR_FABRIC_AXI_VDMA_0_S2MM_INTROUT_INTR, XAxiVdma_WriteIntrHandler, &vdma);

	XAxiVdma_IntrEnable(&vdma, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_WRITE);

	vdma_write_start(&vdma);
}

int main()
{
    init_platform();


	int Status;
	XAxiVdma_Config *vdmaConfig;

	int i;

	/*
	 * Initialize an array of pointers to the 3 frame buffers
	 */
	for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
	{
		pFrames[i] = frameBuf[i];
		memset(pFrames[i], 0, MAX_FRAME);
		Xil_DCacheFlushRange((INTPTR) pFrames[i], MAX_FRAME) ;
	}

	InterruptInit(INTC_DEVICE_ID, &XScuGicInstance);

	/*
	 * Initialize VDMA driver
	 */
	vdmaConfig = XAxiVdma_LookupConfig(VDMA_ID);
	if (!vdmaConfig)
	{
		xil_printf("No video DMA found for ID %d\r\n", VDMA_ID);
	}

	vdmaConfig->MaxFrameStoreNum = DISPLAY_NUM_FRAMES;

	Status = XAxiVdma_CfgInitialize(&vdma, vdmaConfig, vdmaConfig->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		xil_printf("VDMA Configuration Initialization failed %d\r\n", Status);
	}

	/*
	 * Initialize the Display controller and start it
	 */
	Status = DisplayInitialize(&dispCtrl, &vdma, DISP_VTC_ID, DYNCLK_BASEADDR, pFrames, 1280*3);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Display Ctrl initialization failed during demo initialization%d\r\n", Status);
	}

	XAxiVdma_IntrDisable(&vdma, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_READ);
	XAxiVdma_SetCallBack(&vdma, XAXIVDMA_HANDLER_GENERAL, ReadCallBack, (void *)&vdma, XAXIVDMA_READ);
	XAxiVdma_SetCallBack(&vdma, XAXIVDMA_HANDLER_ERROR, ReadErrCallBack, (void *)&vdma, XAXIVDMA_READ);
	InterruptConnect(&XScuGicInstance, XPAR_FABRIC_AXI_VDMA_0_MM2S_INTROUT_INTR, XAxiVdma_ReadIntrHandler, &vdma);
	XAxiVdma_IntrEnable(&vdma, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_READ);


	Status = DisplayStart(&dispCtrl);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Couldn't start display during demo initialization%d\r\n", Status);
	}


	/* Clear frame buffer */
//	memset(dispCtrl.framePtr[dispCtrl.curFrame], 255, MAX_FRAME);

	setInputVdma(1280, 960);

	while(1);

    cleanup_platform();
    return 0;
}

static void WriteCallBack(void *CallbackRef, u32 Mask){
	if ( Mask & XAXIVDMA_IXR_FRMCNT_MASK ){
//		if ( rd_done == 1 ) {
//
//			rd_cnt++;
//			wr_cnt++;
//			if ( rd_cnt >= DISPLAY_NUM_FRAMES )
//				rd_cnt = rd_cnt - DISPLAY_NUM_FRAMES;
//			if ( wr_cnt >= DISPLAY_NUM_FRAMES )
//				wr_cnt = wr_cnt - DISPLAY_NUM_FRAMES;
//
//			XAxiVdma_StartParking(&vdma, wr_cnt, XAXIVDMA_WRITE);
//			DisplayChangeFrame(&dispCtrl, rd_cnt);
//			rd_done = 0;
//		}
//		else
//			return;

		rd_cnt++;
		wr_cnt++;
		if ( rd_cnt >= DISPLAY_NUM_FRAMES )
			rd_cnt = rd_cnt - DISPLAY_NUM_FRAMES;
		if ( wr_cnt >= DISPLAY_NUM_FRAMES )
			wr_cnt = wr_cnt - DISPLAY_NUM_FRAMES;

		XAxiVdma_StartParking(&vdma, wr_cnt, XAXIVDMA_WRITE);
		DisplayChangeFrame(&dispCtrl, rd_cnt);
		rd_done = 0;
	}
}

static void WriteErrCallBack(void *CallbackRef, u32 Mask){
	if ( Mask & XAXIVDMA_IXR_ERROR_MASK ) {
			writeErr++;
		}
}

static void ReadCallBack(void *CallbackRef, u32 Mask){
	if ( Mask & XAXIVDMA_IXR_FRMCNT_MASK ){
//		rd_cnt = dispCtrl.curFrame + 1;
//		if ( rd_cnt > DISPLAY_NUM_FRAMES - 1 ) {
//			rd_cnt = 0;
//		}
//		rd_done = 1;
	}
}

static void ReadErrCallBack(void *CallbackRef, u32 Mask){
	if ( Mask & XAXIVDMA_IXR_ERROR_MASK ) {
		readErr++;
	}
}
