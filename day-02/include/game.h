#ifndef __GAME_H__
#define __GAME_H__

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdint.h>

	typedef enum _game_color
	{
		BLUE,
		RED,
		GREEN,
	} game_color;

	typedef struct _game_node
	{
		struct _game_node *next;
		game_color color;
		uint32_t count;
		uint8_t end_of_segment;
	} game_node;

	typedef struct _game
	{
		game_node *start;
		uint32_t id;
	} game;

	int game_is_valid(const game *game, int r, int g, int b);
	int gamestr(const game *game, char *dst, size_t dst_len);
	int game_cleanup(const game *game);

#ifdef __cplusplus
}
#endif

#endif