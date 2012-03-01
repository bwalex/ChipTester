/*
 ============================================================================
 Name        : ConfigurationReader.c
 Author      : Romel Torres
 Version     :
 Copyright   : No copyright
 Description : Reading a vector file to store them on the ram, Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <dirent.h>

/*Configuration definitions*/
#define CHAR_NUMBER 80 //Number of characters
#define FOLDER_CONFIG_FILE "/home/romel/workspace/ConfigFiles/" //The folder where the testvectors are found
#define DESIGN_NUMBER "<DesignNumber>"//Initial parsing DESIGN_NUMBER
#define DESIGN_NUMBER_END "</DesignNumber>" //Final parsing /DESIGN_NUMBER
#define PIN_DEF "<PinDef>" //Initial parsing PIN_DEF
#define PIN_DEF_END "</PinDef>"//Final parsing /PIN_DEF
#define TEST_VECTOR "<TestVector>"//Initial parsing TEST_VECTOR
#define TEST_VECTOR_END "</TestVector>" //Final parsing /TEST_VECTOR
#define COMMENT_CHAR '#' //Comment definition
#define INPUT_PIN 'A' //Input pin definition
#define OUTPUT_PIN 'Q' //Output pin definition
#define MAX_INPUT_OUTPUT_SIZE 24
#define DESIGN_NUMBER_MASK 31
#define REQ_SWITCH_TARGET 0
#define REQ_TEST_VECTOR 1
#define REQ_SETUP_BITMASK 2
#define REQ_TYPE(r) ((r & 7) << 5)

	typedef struct test_info{
		uint8_t metadata1;
		uint8_t input_vector[3];
		uint8_t output_vector[3];
		uint8_t metadata2;
	}test_info;

	typedef struct change_target {
		uint8_t metadata;
		uint8_t design_number;
	}change_target;

	typedef struct change_bitmask {
		uint8_t metadata;
		uint8_t bit_mask[3];
	}change_bitmask;


	/*
	 * 		This function is used to calculate the number of
	 * 		the last input or output pin declared in the file
	 * */
	int vector_declared_size(char *vector) {
		int i,k =0;
		for(i = 0; i < MAX_INPUT_OUTPUT_SIZE;i++) {
			if(vector[i] == '1') {
				k = i;
			}
		}
		return k;
	}

	/*
	 *  Converts a char array into its correspondent integer value
	 * */
	uint8_t convert_to_integer(char *vector) {
		uint8_t i,real = 0,result = 0;
		while(vector[real]!=0 && vector[real] >= 48 && vector[real] <=57) {
			real++;
		}
		int real2 = real;
		for(i = 0; i < real; i++) {
			if(vector[i]!=0 && vector[i] >= 48 && vector[i] <=57) {
				result = result + pow(10,(real2 - 1))*(vector[i] - 48);
				real2--;
			}

		}
		return result;
	}

	void printint2bin(int n) {
		unsigned int i, k = 32;
		i = 1 << (sizeof(n)*8-1);
		while(i > 0) {
			if(k<=8) {
				if(n & i)
					printf("1");
				else
					printf("0");
			}
			i >>= 1;
			k--;
		}

		}
	/*
		Exiting with error 0 means that the file could not be open.
		Exiting with error 1 means that the operation was successful.
	*/
int main(void)
{
         FILE *fp; 					//For reading the file
         char line [CHAR_NUMBER];
         char is_design_number = 0;
         char is_pin_def = 0;		//Booleans for the program
         char is_test_vector = 0;
         char input_vector_def [MAX_INPUT_OUTPUT_SIZE] = {0};
         char output_vector_def [MAX_INPUT_OUTPUT_SIZE] = {0};
         char result [1];
         test_info test;
         change_target target;
         change_bitmask bit_mask_change;
         uint32_t bit_masking = 0;

         /*This set everything of the structs to zero*/
         memset(&test,0,sizeof(test));
         memset(&target,0,sizeof(target));
         memset(&bit_mask_change,0,sizeof(bit_mask_change));

	     DIR *mydir = opendir(FOLDER_CONFIG_FILE);

	     struct dirent *entry = NULL;

	     while((entry = readdir(mydir))) {
	     char filename[CHAR_NUMBER] = FOLDER_CONFIG_FILE;
	     strcat(filename, entry->d_name);
	     printf("%s\n", filename);
         //Pointer for opening the file
         fp = fopen(filename,"r");
         if( fp == NULL )
               printf("The file %s cannot be opened\n",entry->d_name);
         else {
        	 while(fgets(line, CHAR_NUMBER, fp) != NULL) {
        		 //Defining the position within the test
        		 if(strstr(line,DESIGN_NUMBER)!= NULL)
        			 is_design_number = 1;
        		 else if(strstr(line,DESIGN_NUMBER_END)!= NULL)
        			 is_design_number = 0;
        		 else if(strstr(line,PIN_DEF)!= NULL)
        			 is_pin_def = 1;
        		 //The string exists in the line
        		 else if (strstr(line,PIN_DEF_END)!= NULL)
        			 is_pin_def = 0;
        		 //The string exists in the line
        		 else if (strstr(line,TEST_VECTOR)!= NULL)
        			 is_test_vector = 1;
        		 //The string exists in the line
        		 else if (strstr(line,TEST_VECTOR_END)!= NULL)
        			 is_test_vector = 0;
        		 if(is_design_number && strchr(line, (int)COMMENT_CHAR) == NULL
        			 && strstr(line,DESIGN_NUMBER) == NULL
        			 	 && strstr(line,DESIGN_NUMBER_END) == NULL) {
        			 target.metadata = REQ_TYPE(REQ_SWITCH_TARGET);
        			 target.design_number = convert_to_integer(line) & DESIGN_NUMBER_MASK;
        		 	 }
        		 if(is_pin_def && strchr(line, (int)COMMENT_CHAR) == NULL
        			 && strstr(line,PIN_DEF) == NULL
        			 && strstr(line,PIN_DEF_END) == NULL) {
        		 //If we are in the pin definition and it is not a comment
        			 char *pointer_i, *pointer_o = NULL;
        		 	 pointer_i = strchr(line, (int)INPUT_PIN);
        		 	 pointer_o = strchr(line, (int)OUTPUT_PIN);

        		 	 bit_mask_change.metadata = REQ_TYPE(REQ_SETUP_BITMASK);
        		 	 	 //We have an output pin defined first
        		 	 while(pointer_i != NULL) {
        			 	 	//Initialise to 0
        			 	 	result[0] = 0;
        			 	 	result[1]= 0;
            		 	 	pointer_i = strchr(pointer_i, (int)INPUT_PIN);
            		 	 	 //We have an input pin defined
            		 	 	if(pointer_i != NULL) {
            		 	 		pointer_i = pointer_i + 1;
            		 	 		if(*(pointer_i + 1) >= 48 && *(pointer_i + 1) <= 57)
            		 	 			strncpy(result,pointer_i, 2);
            		 	 		//There is more than one digit number for the pin defined
            		 	 		else {
            		 	 			strncpy(result,pointer_i, 1);
            		 	 			result[1] = 0;
            		 	 		}
            		 	 		//Only one digit number
            		 	 		if(convert_to_integer(result) < MAX_INPUT_OUTPUT_SIZE)
            		 	 			input_vector_def[convert_to_integer(result)] = '1';
            		 	 		/*The '1' means that the output pin has been declared*/
            		 	 	}
            		 	 }
        		 	 while(pointer_o != NULL) {
        			 	 	//Initialise to 0
        			 	 	result[0] = 0;
        			 	 	result[1]= 0;

            		 	 	pointer_o = strchr(pointer_o, (int)OUTPUT_PIN);
            		 	 	 //We have an output pin defined
            		 	 	if(pointer_o != NULL) {
            		 	 		pointer_o = pointer_o + 1;
            		 	 		if(*(pointer_o + 1) >= 48 && *(pointer_o + 1) <= 57)
            		 	 			strncpy(result,pointer_o, 2);
            		 	 		//There is more than one digit number for the pin defined
            		 	 		else {
            		 	 			strncpy(result,pointer_o, 1);
            		 	 			result[1] = 0;
            		 	 		}
            		 	 		//Only one digit number
            		 	 		if(convert_to_integer(result) < MAX_INPUT_OUTPUT_SIZE) {
            		 	 			bit_masking = 1 << (MAX_INPUT_OUTPUT_SIZE - convert_to_integer(result));
            		 	 			bit_mask_change.bit_mask[0] = (uint8_t) (bit_masking >> 16) | bit_mask_change.bit_mask[0];
            		 	 			bit_mask_change.bit_mask[1] = (uint8_t) (bit_masking >> 8) | bit_mask_change.bit_mask[1];
            		 	 			bit_mask_change.bit_mask[2] = (uint8_t) bit_masking | bit_mask_change.bit_mask[2];
            		 	 			output_vector_def[convert_to_integer(result)] = '1';
            		 	 		}
            		 	 		/*The '1' means that the output pin has been declared*/
            		 	 	}
            		 }

        	 }
        		 if(is_test_vector && strchr(line, (int)COMMENT_CHAR) == NULL
        			 && strstr(line,TEST_VECTOR) == NULL
        			 && strstr(line,TEST_VECTOR_END) == NULL) {
        		 //If we are in the test vector pattern and it is not a comment
        			 int i,j = 0,w = 0;
        			 bit_masking = 0;
        			 test.metadata1 = REQ_TYPE(REQ_TEST_VECTOR);
        			 for (i = 0; i < CHAR_NUMBER; i++) {
        			 	 if(line[i]=='0' || line [i] == '1') {
        			 		 while(j > vector_declared_size(input_vector_def) &&
        			 		       output_vector_def[w] !='1' &&
        			 		       	   w <= vector_declared_size(output_vector_def))
        			 		      w++;
        			 		 if(j > vector_declared_size(input_vector_def) &&
        			 				 w <= vector_declared_size(output_vector_def)) {
        			 			  //This generates the proper number set into the memory
			 			 		  uint32_t aux = bit_masking;
        			 			  bit_masking = (line[i] - 48) << (MAX_INPUT_OUTPUT_SIZE - w - 1);
        			 			  test.output_vector[0] = (uint8_t) (test.output_vector[0] | aux >> 16);
        			 			  test.output_vector[1] = (uint8_t) (test.output_vector[1] | aux >> 8);
        			 			  test.output_vector[2] = (uint8_t) (test.output_vector[2] | aux);
        			 		      //Remember to erase this
        			 		      w++;
        			 		      }
			 			 	 while(input_vector_def[j] !='1' &&
			 			 		j <= vector_declared_size(input_vector_def))
			 			 		j++;
			 			 	 if(j <= vector_declared_size(input_vector_def)) {
			 			 		 bit_masking = (uint32_t)(line[i] - 48) << (MAX_INPUT_OUTPUT_SIZE - j -1);
			 			 		 uint32_t aux = bit_masking;
			 			 		 test.input_vector[0] = (uint8_t) (test.input_vector[0] | aux >> 16);
			 			 		 test.input_vector[1] = (uint8_t) (test.input_vector[1] | aux >> 8);
			 			 		 test.input_vector[2] = (uint8_t) (test.input_vector[2] | aux);
			 			 		 j++;
			 			 	 }

        			 	 }
        		 }


        		 /*Just checking stuff*/
        		 printf("Metadata Target\n");
        		 printf("x%X\n",target.metadata);
        		 printf("Design Number:\n");
        		 printf("%d\n",target.design_number);
        		 printf("Metadata Test\n");
        		 printf("x%X\n",test.metadata1);
        		 //convert_to_vector(test,input_vector,output_vector);
                 printf("Input Vector (to memory)\n");
                 printint2bin(test.input_vector[0]);
                 printint2bin(test.input_vector[1]);
                 printint2bin(test.input_vector[2]);
                 printf("\nOutput Vector (to memory)\n");
                 printint2bin(test.output_vector[0]);
                 printint2bin(test.output_vector[1]);
                 printint2bin(test.output_vector[2]);
                 printf("\n BitMask (to memory)\n");
                 printint2bin(bit_mask_change.bit_mask[0]);
                 printint2bin(bit_mask_change.bit_mask[1]);
                 printint2bin(bit_mask_change.bit_mask[2]);
         		 printf("\n");

        	 }

        	 }
         fclose(fp);
         }
	     }
         //Close the file
         closedir(mydir);
         return 1;
}

