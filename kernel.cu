//CUDA Assessment Project for Etecube by Yasin Cesur
//
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdlib>
#include <stdio.h>
#include <iostream>
#include <queue> //queue usage
#include <chrono> //delay usage
#include <thread> //delay usage
#define SIZE 100 //runway lenght, thread count, athlete count
using namespace std;

//Athlete Class   ***other infos may be filled from a file easily as long as ID match***
class Athlete {
    //Members
    public: 
        int id;
        int run = 0;
        string name;
        string gender;
        int age;
        string nation;
    //Fuctions
};

//function for filling random numbers between 1 and 5 to an array
void randomGeneration(int* b) {
    for (int i = 0; i < SIZE; i++)
        b[i] = 1 + (rand() % 5);
}

//function for adding random meters to athlete runs **by GPU**
__global__ void randomMeters(int* a, int* b, int* c)
{
    int i = threadIdx.x; //using threads parallel

    c[i] = a[i] + b[i];
}

int main()
{
    //timer 
    using namespace std::this_thread;
    using namespace std::chrono;
    int runFinish = 0; //variable for checking race finished or not
    int anyOneFinish = 0; //variable for checking if anyone finished or not

    srand((unsigned)time(NULL)); //providing a seed value for random number generation

    int * a, *b, *c;

    queue<int> placementQ; //placement queue

    //creating 100 Athlete Objects
    Athlete TheHundred[SIZE]{}; //Lexa <3

    //memory space
    cudaMallocManaged(&a, SIZE * sizeof(int));
    cudaMallocManaged(&b, SIZE * sizeof(int));
    cudaMallocManaged(&c, SIZE * sizeof(int));
    
    //setting ID's of athletes
    for (int i = 0; i < SIZE; i++) {
        TheHundred[i].id = i + 1;
    }

    cout << "Race is started!\n\n";

    //a loop that will work until race is finished, with 1 second delay
    while (runFinish != 1) 
    {
        randomGeneration(b); //generating random numbers

        //random meters/second 
        randomMeters << <1, SIZE >> > (a, b, c); //calculated by GPU with 1 Block, 100 Threads
        cudaDeviceSynchronize();

        //transferring meters to athlete objects
        for (int j = 0; j < SIZE; j++) {
            TheHundred[j].run += c[j];

            //if any athlete finishes race print current run only once
            if (TheHundred[j].run >= 100 && anyOneFinish != 1) {
                cout << "The athlete whose ID is " << TheHundred[j].id << ", finished first!\n\n";
                cout << "\tID\t**\tRUN\n";
                for (int k = 0; k < SIZE; k++) //print all current situation
                    cout << "\t" << TheHundred[k].id << "\t**\t" << TheHundred[k].run << "\n";
                anyOneFinish = 1;
            }

            //fill race placement
            if (TheHundred[j].run >= 100) {
                placementQ.push(TheHundred[j].id); //put athlete ID to placement if finished
                TheHundred[j].run = -100; //reduce run value to avoid same ID push
            }
        }
            
        //finish the run if each athlete finished race
        if (placementQ.size() >= 100)
            runFinish = 1;

        sleep_for(seconds(1)); //1 second delay
    }

    //print the placement
    int place = 1;
    cout << "\n\n\tPLACE\t**\tID\n";
    while (!placementQ.empty()) {
        cout << "\t" << place << "\t**\t" << placementQ.front();
        placementQ.pop();
        cout << "\n";

        place++;
    }

    //free memory space
    cudaFree(a);
    cudaFree(b);
    cudaFree(c);
   
    return 0;
}