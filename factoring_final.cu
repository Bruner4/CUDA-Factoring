
////////////////////////////////             include & Definitions             ///////////////////////////////////////////////////////


#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define SIZE 1024
#define ALL_OK printf("\nProgram is working normally.\n");






////////////////////////////////               PARALLEL CODE                ///////////////////////////////////////////////////////


__global__ void trial(long int* prime, long int* number, long int* length, int* check) {

    long int i = threadIdx.x + blockIdx.x * blockDim.x;

    if ((i > 1) && (i <= *length))
    {
        if (prime[i])
        {
            if (i * i == *number)
            {
                printf(" %d raised to square   ---------   proof: in fact %d * %d = %d, that is equal to value entered (%d)\n", i, i, i, (i * i), *number);
                *check = 1;

            }

            if (*number % i == 0 && i * i != *number)
            {
                printf(" %d and %d             ---------   proof: in fact %d * %d = %d, that is equal to value entered (%d)\n", i, (*number / i), i, (*number / i), (i * (*number / i)), *number);
                *check = 1;
            }

        }

    }

    void __syncthreads();

}

///////////////////////////////////           END OF PARALLEL CODE          //////////////////////////////////////////////////




///////////////////////////////////           SEQUENTIAL CODE             //////////////////////////////////////////////////


void main()
{
    int n = 2, nDevices, threadsPerBlock, threadsDim, gridSize, * checkPrimeHost, * checkPrimeDeviceFinal;
    static long int* d_length, * d_prime, * d_number;
    long int elim, number, * prime;
    bool exit_status = false;


    //Check GPU specs and if it is capable of run program.

    /*Guardare sempre I limiti massimi dell’hw (warp size,
    SM, max blocks, max threads per block)
    2. I thread all’interno del blocco dovrebbero essere
        multipli dello WARP size
        3. Partire da numeri grandi di threads e blocks,
        calcolare lo speed up e provare a diminuire i
        parametri cercando la soluzione ideale */


    cudaGetDeviceCount(&nDevices);
    for (int i = 0; i < nDevices; i++)
    {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        printf("            GPU SPECS\n");
        printf("==========================================================================================\n");
        printf("Device Number:                   %d\n", i);
        printf("Device Name:                     %s\n", prop.name);
        printf("Memory Warp Size:                %d\n", prop.warpSize);
        printf("Memory Shared Memory Per Block:  %d\n", (int)prop.sharedMemPerBlock);
        printf("Max Threads Per Block:           %d\n", prop.maxThreadsPerBlock);
        printf("Max Threads Dimension:           %d\n", prop.maxThreadsDim[3]);
        printf("Max Grid Size:                   %d\n", prop.maxGridSize[3]);
        printf("Multi Processor Count:           %d\n", prop.multiProcessorCount);
        printf("Memory Pitch by memory copy:     %d\n", (int)prop.memPitch);
        printf("Least device CC:                 %d\n", prop.major);
        printf("==========================================================================================\n\n");
        threadsPerBlock = prop.maxThreadsPerBlock;
        threadsDim = prop.maxThreadsDim[3];
        gridSize = prop.maxGridSize[3];
    }


    while (exit_status == false)
    {
        printf("            BEGIN\n\nPlease, enter number to factorize. To exit insert 0 and then press enter.\n"
            "Note: do not insert values major than 2147483647 because of long int size.\n\n "
            "                           Number:   ");
        scanf("%d", &number);
        if (number == 0)
        {
            exit_status = true;
            printf("\nExit status activated. Aborting process...\n\n\n");
            break;
        }

        clock_t start, end;
        double tempo;
        start = clock();

        long int length = floor(sqrt(number));

        prime = (long int*)malloc(number * sizeof(long int));

        cudaMalloc((void**)&d_prime, (length+1) * sizeof(long int));
        cudaMalloc((void**)&d_number, sizeof(long int));
        cudaMalloc((void**)&d_length, sizeof(long int));
        cudaMalloc((void**)&checkPrimeDeviceFinal, (sizeof(int)));
        checkPrimeHost = 0;



        //Eratosthenes Sieve

        for (int i = 0; i < length; i++)
        {
            prime[i] = 1;
        }


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

        cudaMemcpy(d_prime, prime, (length+1) * sizeof(long int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_number, &number, sizeof(long int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_length, &length, sizeof(long int), cudaMemcpyHostToDevice);

        cudaMemcpy(checkPrimeDeviceFinal, checkPrimeHost, sizeof(int), cudaMemcpyHostToDevice);

        int requiredBlocks = (length / SIZE) + 1;

        dim3 grid(requiredBlocks, 1, 1);
        dim3 block(SIZE, 1, 1);


        printf("\n\nNumber %d can be factored in following manners:\n\n", number);
        trial << < grid, block >> > (d_prime, d_number, d_length, checkPrimeDeviceFinal);

        int* check2;
        check2 = (int*)malloc(sizeof(int));

        cudaMemcpy(check2, checkPrimeDeviceFinal, sizeof(int), cudaMemcpyDeviceToHost);


        if (*check2 == 0)
        {
            printf("Number %d is a prime.\n", number);
            printf("Radice quadrata: %d", length);
        }


        free(prime);
        cudaFree(d_prime);
        cudaFree(d_number);
        cudaFree(d_length);
        cudaFree(checkPrimeDeviceFinal);

        end = clock();
        tempo = ((double)(end - start)) / CLOCKS_PER_SEC;
        printf("\n\nElapsed time: %f\n", tempo);
        printf("==========================================================================================\n\n");
    }

}



//////////////////////////////////////        END OF SEQUENTIAL CODE           //////////////////////////////////////////////
