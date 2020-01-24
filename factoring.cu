#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <math.h>
#include <stdio.h>
#include <time.h>
#define SIZE 512

__global__ void trial(long int *prime, long int *number, long int *length, long int *val, long int *val2) {
	
	int i = threadIdx.x;

	if ((i > 1) && (i < *length))
	{
		if (prime[i])
		{
			*val = i;
			if (*val * *val == *number)
			{
//				printf("\nI divisori primi sono %ld e %ld\n", val, val);
				*val2 = *val;
				return;
			}
			if (*number % *val == 0)
			{
//				printf("\nI divisori primi sono %ld ", val);
				*val2 = *number / *val;
//				printf("e %ld.\n", val2);
			}
		}
	}

}


void main()
{
	clock_t start, end;
	double tempo;
	start = clock();

	long int *d_length;
	long int *prime;
	long int *d_prime;
	int n = 2;
	long int elim;
	long int number;
	long int *d_number;
	long int val, val2;
	long int* d_val, * d_val2;

	printf("Inserisci numero da fattorizzare: ");
	scanf("%d", &number);

	long int length = floor(sqrt(number));

	prime = (long int *)malloc(SIZE * sizeof(long int));
	cudaMalloc((void**) &d_prime, SIZE * sizeof(long int));
	cudaMalloc((void**) &d_number, sizeof(long int));
	cudaMalloc((void**) &d_length, sizeof(long int));
	cudaMalloc((void**) &d_val, sizeof(long int));
	cudaMalloc((void**) &d_val2, sizeof(long int));


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
/*	for (int i = 2; i < length; i++)
		printf("%d: %d - ", i, prime[i]);
	printf("\nLa lunghezza e' di %d\n", length);*/

	cudaMemcpy(d_prime, &prime, SIZE * sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_number, &number, sizeof(long int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_length, &length, sizeof(long int), cudaMemcpyHostToDevice);

	trial << <1, 1 >> > (d_prime, d_number, d_length, d_val, d_val2);

	cudaMemcpy(&val, d_val, sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(&val2, d_val2, sizeof(int), cudaMemcpyDeviceToHost);

	printf("\nI divisori sono %ld e %ld.\n", val, val2);

	free(prime);

	cudaFree(d_prime);
	cudaFree(d_number);
	cudaFree(d_length);
	cudaFree(d_val);
	cudaFree(d_val2);

	end = clock();
	tempo = ((double)(end - start)) / CLOCKS_PER_SEC;
	printf("Tempo: %f\n", tempo);
}
