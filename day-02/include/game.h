#ifndef __GAME_H__
#define __GAME_H__

#include <stdint.h>

typedef enum _game_color {
	BLUE,
	RED,
	GREEN,
} game_color;

typedef struct _game_node {
	struct _game_node *next;
	game_color color;
	uint8_t end_of_segment;
} game_node;

typedef struct _game {
	game_node *start;
	uint32_t id;
} game;

#endif