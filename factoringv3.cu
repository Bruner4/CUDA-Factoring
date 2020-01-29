#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define SIZE 1024

__global__ void trial(long int *prime, long int *number, long int *length) {
	
	long int i = threadIdx.x + blockIdx.x * blockDim.x;
/*	long int i = blockIdx.x * blockDim.x * blockDim.y *
		blockDim.z + threadIdx.z * blockDim.y * blockDim.x +
		threadIdx.y * blockDim.x + threadIdx.x;
*/

	if ((i > 1) && (i <= *length))
	{
		if (prime[i])
		{
			long int val = i;
			if (val * val == *number)
			{
				printf("\nPrime factors are %ld and %ld\n", val, val);
				return;
			}
			if (*number % val == 0)
			{
				printf("\nPrime factors are %ld ", val);
				long int val2 = *number / val;
				printf("and %ld.\n", val2);
			}
		}
	}
	__syncthreads();
}


void main()
{
	long int *d_length;
	long int *prime;
	long int *d_prime;
	long int n = 2;
	long int elim;
	long int number;
	long int *d_number;

	printf("Enter number to factorize: ");
	scanf("%d", &number);

	clock_t start, end;
	double tempo;
	start = clock();

	long int length = floor(sqrt(number));

	prime = (long int *)malloc(SIZE * sizeof(long int));
	cudaMalloc((void**) &d_prime, SIZE * sizeof(long int));
	cudaMalloc((void**) &d_number, sizeof(long int));
	cudaMalloc((void**) &d_length, sizeof(long int));

	//Eratosthenes Sieve

	for (int i = 0; i < length; i++)
		prime[i] = 1;

	while (n <= length)
	{
		if (prime[n] == 1)
		{
			elim = n + n;
			while (elim <= length)
			{
				prime[elim] = 0;
				elim += n;
			}
		}
		n++;
	}

	cudaMemcpy(d_prime, prime, SIZE * sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_number, &number, sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_length, &length, sizeof(long int), cudaMemcpyHostToDevice);

	int requiredBlocks = (length / SIZE) + 1;
	
	dim3 grid(requiredBlocks, 1, 1);
	dim3 block(SIZE, 1, 1);
	
	trial << <grid, block >> > (d_prime, d_number, d_length);

	free(prime);

	cudaFree(d_prime);
	cudaFree(d_number);
	cudaFree(d_length);

	end = clock();
	tempo = ((double)(end - start)) / CLOCKS_PER_SEC;
	printf("Time: %f\n", tempo);
}
