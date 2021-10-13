///******************************************************************************
//*
//* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
//*
//* Permission is hereby granted, free of charge, to any person obtaining a copy
//* of this software and associated documentation files (the "Software"), to deal
//* in the Software without restriction, including without limitation the rights
//* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//* copies of the Software, and to permit persons to whom the Software is
//* furnished to do so, subject to the following conditions:
//*
//* The above copyright notice and this permission notice shall be included in
//* all copies or substantial portions of the Software.
//*
//* Use of the Software is limited solely to applications:
//* (a) running on a Xilinx device, or
//* (b) that interact with a Xilinx device through a bus or interconnect.
//*
//* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
//* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//* SOFTWARE.
//*
//* Except as contained in this notice, the name of the Xilinx shall not be used
//* in advertising or otherwise to promote the sale, use or other dealings in
//* this Software without prior written authorization from Xilinx.
//*
//******************************************************************************/
//
///*
// * helloworld.c: simple test application
// *
// * This application configures UART 16550 to baud rate 9600.
// * PS7 UART (Zynq) is not initialized by this application, since
// * bootrom/bsp configures it to baud rate 115200
// *
// * ------------------------------------------------
// * | UART TYPE   BAUD RATE                        |
// * ------------------------------------------------
// *   uartns550   9600
// *   uartlite    Configurable only in HW design
// *   ps7_uart    115200 (configured by bootrom/bsp)
// */
//
//#include "display_ctrl/display_ctrl.h"
//#include <stdio.h>
//#include "math.h"
//#include <ctype.h>
//#include <stdlib.h>
//#include "xil_types.h"
//#include "xil_cache.h"
//#include "xparameters.h"
//#include "vdma/vdma.h"
//#include "sleep.h"
//#include "xscugic.h"
//#include "platform.h"
//#include "intr/zynq_interrupt.h"
//
//
//
//#define MAX_FRAME 1280*960*3
//
//
//#define DYNCLK_BASEADDR XPAR_AXI_DYNCLK_0_BASEADDR
//#define SOURCE_VDMA_ID 	XPAR_AXIVDMA_0_DEVICE_ID
//#define SINK_VDMA_ID 	XPAR_AXIVDMA_1_DEVICE_ID
//#define DISP_VTC_ID 	XPAR_VTC_0_DEVICE_ID
//#define VID_VTC_IRPT_ID XPS_FPGA3_INT_ID
//
//#define INTC_DEVICE_ID  	XPAR_SCUGIC_SINGLE_DEVICE_ID
//#define INTC_BASE_ADDR  	XPAR_SCUGIC_0_CPU_BASEADDR
//#define INTC_DIST_BASE_ADDR XPAR_SCUGIC_DIST_BASEADDR
//
//u8 frameBuf[DISPLAY_NUM_FRAMES][MAX_FRAME] __attribute__ ((aligned(64)));
//u8 *pFrames[DISPLAY_NUM_FRAMES]; //array of pointers to the frame buffers
//
//XAxiVdma vdmaInput;
//XScuGic XScuGicInstance;
//
//static u8 wr_cnt;
//static int writeErr;
//
//
//
//static void WriteCallBack(void *CallbackRef, u32 Mask);
//static void WriteErrCallBack(void *CallbackRef, u32 Mask);
//
//
//void setInputVdma(int width, int height){
//	int Status;
//	XAxiVdma_Config * vdmaConfig;
//
//	vdmaConfig = XAxiVdma_LookupConfig(SINK_VDMA_ID);
//	if (!vdmaConfig)
//	{
//		xil_printf("No video DMA found for ID %d\r\n", SINK_VDMA_ID);
//	}
//
//	Status = XAxiVdma_CfgInitialize(&vdmaInput, vdmaConfig, vdmaConfig->BaseAddress);
//	if (Status != XST_SUCCESS)
//	{
//		xil_printf("VDMA Configuration Initialization failed %d\r\n", Status);
//	}
//
//	vdma_write_stop(&vdmaInput);
//	XAxiVdma_IntrDisable(&vdmaInput, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_WRITE);
//
//	vdma_writes_init(SINK_VDMA_ID, &vdmaInput, width * 3, height, width * 3,
//			(unsigned int)pFrames[0], (unsigned int)pFrames[1], (unsigned int)pFrames[2]);
//	InterruptConnect(&XScuGicInstance, XPAR_FABRIC_AXI_VDMA_1_S2MM_INTROUT_INTR, (Xil_InterruptHandler)XAxiVdma_WriteIntrHandler, &vdmaInput);
//
//	XAxiVdma_SetCallBack(&vdmaInput, XAXIVDMA_HANDLER_GENERAL, WriteCallBack, (void *)&vdmaInput, XAXIVDMA_WRITE);
//	XAxiVdma_SetCallBack(&vdmaInput, XAXIVDMA_HANDLER_ERROR, WriteErrCallBack, (void *)&vdmaInput, XAXIVDMA_WRITE);
//
//
//	XAxiVdma_IntrEnable(&vdmaInput, XAXIVDMA_IXR_ALL_MASK, XAXIVDMA_WRITE);
//
//	vdma_write_start(&vdmaInput);
//}
//
//int main()
//{
//    init_platform();
//
//	int i;
//
//	/*
//	 * Initialize an array of pointers to the 3 frame buffers
//	 */
//	for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
//	{
//		pFrames[i] = frameBuf[i];
//		memset(pFrames[i], 0, MAX_FRAME);
//		Xil_DCacheFlushRange((INTPTR) pFrames[i], MAX_FRAME) ;
//	}
//
//	InterruptInit(INTC_DEVICE_ID, &XScuGicInstance);
//
//	setInputVdma(1280, 960);
//
//	while(1);
//
//    cleanup_platform();
//    return 0;
//}
//
//static void WriteCallBack(void *CallbackRef, u32 Mask){
//	if ( Mask & XAXIVDMA_IXR_FRMCNT_MASK ){
//		wr_cnt++;
//		if ( wr_cnt >= DISPLAY_NUM_FRAMES - 1 ) {
//			wr_cnt = 0;
//		}
//		XAxiVdma_StartParking(&vdmaInput, wr_cnt, XAXIVDMA_WRITE);
//	}
//}
//
//static void WriteErrCallBack(void *CallbackRef, u32 Mask){
//	if ( Mask & XAXIVDMA_IXR_ERROR_MASK ) {
//			writeErr++;
//		}
//}
//
