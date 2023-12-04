#ifndef __GAME_READER_H__
#define __GAME_READER_H__

#include <stdint.h>

typedef enum {
	BLUE,
	RED,
	GREEN,
} game_color;

typedef struct {
	struct game_node *next;
	game_color color;
	uint8_t end_of_segment;
} game_node;

typedef struct {
	game_node *start;
	uint32_t id;
} game;

game game_from_path(char *const path);

#endif