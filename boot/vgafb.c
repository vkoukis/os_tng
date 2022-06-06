#include <inttypes.h>

#define WIDTH 80

uint16_t * vgafb_cellp(unsigned int row, int col)
{
	return (uint16_t *)(0xB8000) + row * WIDTH + col;
}
