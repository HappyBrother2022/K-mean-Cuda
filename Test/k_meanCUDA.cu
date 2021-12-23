#include "k_meanCUDA.cuh"
#include "cuda.h"
#include "cuda_runtime.h"
#include "math.h"
#include "device_launch_parameters.h"
#include "k_mean.h"

#define tile 32
//calculate the Distance between two points : formula d=√ ∑i(x−x2i)^2+(y−yi)^2 - 
//Where (x,y) represent the centroid’s coordinates, and (xi,yi) represent the data-point’s coordinates.
//Device to execute in device - meaning call the function in device 

__device__ double calculatedistanceGPU(unit* point1, unit* point2) {
	return (double)sqrt((double)pow(point1->dim1 - point2->dim1, 2) + (double)pow(point1->dim2 - point2->dim2, 2) + (double)pow(point1->dim3 - point2->dim3, 2) + (double)pow(point1->dim4 - point2->dim4, 2));
}
//static and funtion pointers not allowed 
// We find the closest centroid to the points
__global__ void closestcentroidGPU(unit* points, unit* centroids, int numofcentr, int numofpoints) {

	int threadsPerBlock = blockDim.x * blockDim.y * blockDim.z;
	int threadPosInBlock = threadIdx.x + blockDim.x * threadIdx.y + blockDim.x * blockDim.y * threadIdx.z;
	int blockPosInGrid = blockIdx.x + gridDim.x * blockIdx.y + gridDim.x * gridDim.y * blockIdx.z;
	int tid = blockPosInGrid * threadsPerBlock + threadPosInBlock;

	if (tid < numofpoints) {
		double dist = 0;
		double firstdistance = calculatedistanceGPU(&points[tid], &centroids[0]);
		points[tid].cluster = 0;
		for (int i = 1; i < numofcentr; i++) {
			dist = calculatedistanceGPU(&points[tid], &centroids[i]);// calculating the distance between the centroid and the point
			if (dist <= firstdistance) //getting the smaller distance till we get the smallest(end of forloop) distance
			{ 
				points[tid].cluster = i;
				firstdistance = dist;
			}
		}
	}
}


//
__global__ void closestcentroidSharedGPU(unit* points, unit* centroids, int numofcentr, int numofpoints) {

	int threadsPerBlock = blockDim.x * blockDim.y * blockDim.z;
	int threadPosInBlock = threadIdx.x + blockDim.x * threadIdx.y + blockDim.x * blockDim.y * threadIdx.z;
	int blockPosInGrid = blockIdx.x + gridDim.x * blockIdx.y + gridDim.x * gridDim.y * blockIdx.z;
	int tid = blockPosInGrid * threadsPerBlock + threadPosInBlock;

	//Managing comunication and syncronization
	//within a block, threads share data via shared memory

	__shared__ unit sh_points[tile*tile];
	__shared__ unit sh_centrs[4];
	
	// finding which point belongs to which centroid

	if (tid < numofpoints) {
		sh_points[threadPosInBlock] = points[tid];
		if (tid%threadsPerBlock ==0) {
			for (int i = 0; i < numofcentr; i++) {
				sh_centrs[i] = centroids[i];
			}
			
		}
	//Synchronizes all threads within a block 
	// prevent data hazards
		__syncthreads();

		double dist = 0;
		double firstdistance = calculatedistanceGPU(&sh_points[threadPosInBlock], &sh_centrs[0]);
		sh_points[threadPosInBlock].cluster = 0;
	
	//calculate smallest distance between a point and centeroid ina particular block

		for (int i = 1; i < numofcentr; i++) {
			dist = calculatedistanceGPU(&sh_points[threadPosInBlock], &sh_centrs[i]);
			if (dist <= firstdistance) {
				sh_points[threadPosInBlock].cluster = i;
				firstdistance = dist;
			}
		}
		__syncthreads();

		// Assinging all the shared points in a block to the particular thread id

		points[tid] = sh_points[threadPosInBlock];
		
		__syncthreads();
	}
}